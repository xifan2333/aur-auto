#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FIX=0
VERBOSE=0

print_usage() {
	cat <<'HELP'
Usage: scripts/lint.sh [OPTIONS]

Run comprehensive lint and consistency checks on aur-auto repository.

Options:
  --fix          Automatically fix format issues and regenerate README
  -v, --verbose  Show detailed output for passed checks
  -h, --help     Show this help message
HELP
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--fix)
			FIX=1
			shift
			;;
		-v | --verbose)
			VERBOSE=1
			shift
			;;
		-h | --help)
			print_usage
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			print_usage >&2
			exit 1
			;;
	esac
done

ERRORS=0
WARNINGS=0

log_info() {
	printf '\033[1;34m::\033[0m %s\n' "$*"
}

log_pass() {
	printf '\033[1;32m  ✓\033[0m %s\n' "$*"
}

log_warn() {
	printf '\033[1;33m  ⚠\033[0m %s\n' "$*"
	WARNINGS=$((WARNINGS + 1))
}

log_fail() {
	printf '\033[1;31m  ✗\033[0m %s\n' "$*"
	ERRORS=$((ERRORS + 1))
}

# 1. Metadata check
log_info "Checking maintainer metadata..."
META_FILE="${ROOT_DIR}/metadata/maintainers.env"
if [[ ! -f "${META_FILE}" ]]; then
	log_fail "Metadata file missing: metadata/maintainers.env"
else
	# shellcheck disable=SC1090
	source "${META_FILE}"
	if [[ -z "${AUR_USER:-}" ]]; then
		log_fail "Missing AUR_USER in metadata/maintainers.env"
	fi
	if [[ -z "${AUR_EMAIL:-}" ]]; then
		log_fail "Missing AUR_EMAIL in metadata/maintainers.env"
	fi
	if [[ "${ERRORS}" -eq 0 ]]; then
		log_pass "metadata/maintainers.env valid (${AUR_USER} <${AUR_EMAIL}>)"
	fi
fi

# 2. Package structure and contract checks
log_info "Checking package contracts (PKGBUILD and upstream.sh)..."
pkg_dirs=()
while IFS= read -r -d '' dir; do
	pkg_dirs+=("${dir}")
done < <(find "${ROOT_DIR}/pkgs" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

if [[ ${#pkg_dirs[@]} -eq 0 ]]; then
	log_fail "No package directories found in pkgs/"
fi

for pkg_dir in "${pkg_dirs[@]}"; do
	pkg_name="$(basename "${pkg_dir}")"
	pkgbuild="${pkg_dir}/PKGBUILD"
	upstream="${pkg_dir}/upstream.sh"
	pkg_err=0

	# Check PKGBUILD existence
	if [[ ! -f "${pkgbuild}" ]]; then
		log_fail "[${pkg_name}] Missing PKGBUILD"
		pkg_err=1
	else
		# Verify PKGBUILD can be parsed and defines required variables
		pkg_info="$(bash -c "source '${pkgbuild}' 2>/dev/null; printf '%s|%s|%s' \"\${pkgname:-}\" \"\${pkgver:-}\" \"\${pkgrel:-}\"" || true)"
		p_name="${pkg_info%%|*}"
		rest="${pkg_info#*|}"
		p_ver="${rest%%|*}"
		p_rel="${rest#*|}"

		if [[ -z "${p_name}" ]]; then
			log_fail "[${pkg_name}] PKGBUILD does not define 'pkgname' or failed to parse"
			pkg_err=1
		elif [[ "${p_name}" != "${pkg_name}" ]]; then
			log_fail "[${pkg_name}] Directory name '${pkg_name}' does not match pkgname '${p_name}'"
			pkg_err=1
		fi

		if [[ -z "${p_ver}" ]]; then
			log_fail "[${pkg_name}] PKGBUILD does not define 'pkgver'"
			pkg_err=1
		fi

		if [[ -z "${p_rel}" ]]; then
			log_fail "[${pkg_name}] PKGBUILD does not define 'pkgrel'"
			pkg_err=1
		fi
	fi

	# Check upstream.sh existence & permissions
	if [[ ! -f "${upstream}" ]]; then
		log_fail "[${pkg_name}] Missing upstream.sh"
		pkg_err=1
	else
		if [[ ! -x "${upstream}" ]]; then
			if [[ "${FIX}" -eq 1 ]]; then
				chmod +x "${upstream}"
				log_pass "[${pkg_name}] Fixed executable permissions on upstream.sh"
			else
				log_fail "[${pkg_name}] upstream.sh is not executable (run 'chmod +x ${upstream}' or use --fix)"
				pkg_err=1
			fi
		fi

		# Verify required functions in upstream.sh
		check_funcs="$(bash -c "
			export ROOT_DIR='${ROOT_DIR}' PKG_DIR='${pkg_dir}' PKG_NAME='${pkg_name}'
			source '${upstream}' 2>/dev/null
			missing=()
			declare -f pkg_detect_latest >/dev/null || missing+=('pkg_detect_latest')
			declare -f pkg_get_update_params >/dev/null || missing+=('pkg_get_update_params')
			declare -f pkg_update_files >/dev/null || missing+=('pkg_update_files')
			echo \"\${missing[*]}\"
		" || true)"

		if [[ -n "${check_funcs}" ]]; then
			log_fail "[${pkg_name}] upstream.sh is missing required function(s): ${check_funcs}"
			pkg_err=1
		fi
	fi

	if [[ "${pkg_err}" -eq 0 && "${VERBOSE}" -eq 1 ]]; then
		log_pass "Package [${pkg_name}] contract OK"
	fi
done

if [[ "${ERRORS}" -eq 0 ]]; then
	log_pass "All ${#pkg_dirs[@]} packages passed contract checks"
fi

# Collect all shell scripts
shell_files=()
while IFS= read -r -d '' f; do
	shell_files+=("${f}")
done < <(find "${ROOT_DIR}/scripts" "${ROOT_DIR}/pkgs" -type f \( -name "*.sh" -o -name "*.install" \) -print0 | sort -z)

# 3. ShellCheck
log_info "Running ShellCheck..."
if command -v shellcheck >/dev/null 2>&1; then
	sc_errors=0
	for file in "${shell_files[@]}"; do
		if [[ "${file}" == *.install ]]; then
			if ! shellcheck -s bash "${file}"; then
				sc_errors=$((sc_errors + 1))
			fi
		else
			if ! shellcheck "${file}"; then
				sc_errors=$((sc_errors + 1))
			fi
		fi
	done
	if [[ "${sc_errors}" -gt 0 ]]; then
		log_fail "ShellCheck found issues in ${sc_errors} file(s)"
	else
		log_pass "ShellCheck passed on ${#shell_files[@]} shell file(s)"
	fi
else
	log_warn "shellcheck not found in PATH, skipping ShellCheck"
fi

# 4. shfmt formatting check
log_info "Running shfmt format check..."
if command -v shfmt >/dev/null 2>&1; then
	if [[ "${FIX}" -eq 1 ]]; then
		shfmt -w -i 0 -ci "${shell_files[@]}"
		log_pass "Formatted ${#shell_files[@]} shell file(s) with shfmt"
	else
		if ! shfmt -d -i 0 -ci "${shell_files[@]}"; then
			log_fail "Shell formatting mismatch found. Run './scripts/lint.sh --fix' to auto-format"
		else
			log_pass "Shell formatting is clean"
		fi
	fi
else
	log_warn "shfmt not found in PATH, skipping format check"
fi

# 5. GitHub Actions workflow lint (actionlint)
log_info "Checking GitHub Actions workflows..."
if command -v actionlint >/dev/null 2>&1; then
	if actionlint "${ROOT_DIR}/.github/workflows/"*.yml; then
		log_pass "actionlint passed"
	else
		log_fail "actionlint found workflow issues"
	fi
elif command -v docker >/dev/null 2>&1; then
	if docker run --rm -v "${ROOT_DIR}:/repo" -w /repo rhysd/actionlint:latest 2>&1; then
		log_pass "actionlint passed (via docker)"
	else
		log_fail "actionlint found workflow issues"
	fi
else
	log_warn "actionlint / docker not available, skipping actionlint"
fi

# 6. Documentation sync check
log_info "Checking README synchronization..."
# Capture current status before regenerating
before_diff="$(git -C "${ROOT_DIR}" status --porcelain README.md README.zh.md)"

# Run build-readme.sh
"${ROOT_DIR}/scripts/build-readme.sh" >/dev/null

after_diff="$(git -C "${ROOT_DIR}" status --porcelain README.md README.zh.md)"

if [[ -n "${after_diff}" && "${before_diff}" != "${after_diff}" ]]; then
	if [[ "${FIX}" -eq 1 ]]; then
		log_pass "README.md and README.zh.md regenerated successfully"
	else
		# Restore original state if we only wanted to check
		git -C "${ROOT_DIR}" checkout -- README.md README.zh.md 2>/dev/null || true
		log_fail "README.md / README.zh.md are out of date. Run './scripts/lint.sh --fix' or 'scripts/build-readme.sh'"
	fi
else
	log_pass "README.md and README.zh.md are up to date"
fi

echo ""
if [[ "${ERRORS}" -gt 0 ]]; then
	printf '\033[1;31mFAILED:\033[0m %d error(s), %d warning(s) found.\n' "${ERRORS}" "${WARNINGS}"
	exit 1
else
	printf '\033[1;32mPASSED:\033[0m All checks passed (%d warning(s)).\n' "${WARNINGS}"
	exit 0
fi
