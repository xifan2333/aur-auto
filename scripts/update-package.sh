#!/usr/bin/env bash
set -euo pipefail

print_usage() {
	cat <<'EOF'
Usage: update-package.sh <pkgname> [--force]

Detects upstream updates for the specified package, downloads the new source,
updates PKGBUILD metadata, and regenerates .SRCINFO. Package-specific logic
must be implemented in pkgs/<pkgname>/upstream.sh.
EOF
}

if [[ $# -lt 1 ]]; then
	print_usage >&2
	exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_NAME="$1"
shift

FORCE=0
while [[ $# -gt 0 ]]; do
	case "$1" in
		--force)
			FORCE=1
			shift
			;;
		-h|--help)
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

PKG_DIR="${ROOT_DIR}/pkgs/${PKG_NAME}"
if [[ ! -d "${PKG_DIR}" ]]; then
	echo "Package directory not found: ${PKG_DIR}" >&2
	exit 1
fi

UPSTREAM_HELPER="${PKG_DIR}/upstream.sh"
if [[ ! -f "${UPSTREAM_HELPER}" ]]; then
	echo "Missing upstream helper script: ${UPSTREAM_HELPER}" >&2
	exit 1
fi

export ROOT_DIR PKG_DIR PKG_NAME
# shellcheck source=/dev/null
source "${UPSTREAM_HELPER}"

if ! declare -f pkg_detect_latest >/dev/null; then
	echo "pkg_detect_latest is not defined in ${UPSTREAM_HELPER}" >&2
	exit 1
fi

if ! declare -f pkg_source_info >/dev/null; then
	echo "pkg_source_info is not defined in ${UPSTREAM_HELPER}" >&2
	exit 1
fi

if ! declare -f pkg_update_files >/dev/null; then
	echo "pkg_update_files is not defined in ${UPSTREAM_HELPER}" >&2
	exit 1
fi

current_version="$(awk -F'= *' '$1=="pkgver"{print $2; exit}' "${PKG_DIR}/PKGBUILD")"
if [[ -z "${current_version}" ]]; then
	echo "Unable to determine current pkgver from PKGBUILD" >&2
	exit 1
fi

latest_version="$(pkg_detect_latest)"
if [[ -z "${latest_version}" ]]; then
	echo "pkg_detect_latest returned empty version" >&2
	exit 1
fi

if [[ "${latest_version}" == "${current_version}" && "${FORCE}" -eq 0 ]]; then
	echo "Already up-to-date (${current_version})"
	exit 0
fi

read -r source_url artifact <<<"$(pkg_source_info "${latest_version}")"
if [[ -z "${source_url}" || -z "${artifact}" ]]; then
	echo "pkg_source_info must return '<url> <filename>'" >&2
	exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
artifact_path="${tmpdir}/${artifact}"

if declare -f pkg_fetch_source >/dev/null; then
	pkg_fetch_source "${source_url}" "${artifact_path}"
else
	curl -fsSL --retry 3 --retry-delay 2 -o "${artifact_path}" "${source_url}"
fi

sha256="$(sha256sum "${artifact_path}" | awk '{print $1}')"
pkg_update_files "${latest_version}" "${sha256}" "${source_url}" "${artifact}"

echo "Updated ${PKG_NAME} ${current_version} -> ${latest_version}"
