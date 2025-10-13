#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
META_FILE="${ROOT_DIR}/metadata/maintainers.env"
PKG_META_DIR="${ROOT_DIR}/metadata/packages"
TEMPLATE_EN="${ROOT_DIR}/docs/readme.en.template.md"
TEMPLATE_ZH="${ROOT_DIR}/docs/readme.zh.template.md"
OUTPUT_ROOT="${ROOT_DIR}/README.md"
OUTPUT_ZH="${ROOT_DIR}/README.zh.md"

if [[ ! -f "${META_FILE}" ]]; then
	echo "Metadata file missing: ${META_FILE}" >&2
	exit 1
fi

if [[ ! -f "${TEMPLATE_EN}" ]]; then
	echo "English template missing: ${TEMPLATE_EN}" >&2
	exit 1
fi

if [[ ! -f "${TEMPLATE_ZH}" ]]; then
	echo "Chinese template missing: ${TEMPLATE_ZH}" >&2
	exit 1
fi

# shellcheck disable=SC1090
source "${META_FILE}"

: "${AUR_USER:?Missing AUR_USER in ${META_FILE}}"
: "${AUR_EMAIL:?Missing AUR_EMAIL in ${META_FILE}}"
: "${GITHUB_SLUG:=}"

export AUR_USER AUR_EMAIL GITHUB_SLUG

declare -a pkg_dirs=()
while IFS= read -r -d '' dir; do
	pkg_dirs+=("${dir}")
done < <(find "${ROOT_DIR}/pkgs" -mindepth 1 -maxdepth 1 -type d -print0)

declare -A dir_map=()
for dir in "${pkg_dirs[@]}"; do
	base="$(basename "${dir}")"
	dir_map["${base}"]="${dir}"
done

render_template() {
	local template="$1"
	local output="$2"

	# Export variables for Python
	export TEMPLATE_FILE="${template}"
	export PKG_TABLE="${table}"

	# Use Python for reliable multi-line replacement
	python3 -c '
import os
with open(os.environ["TEMPLATE_FILE"], "r") as f:
    content = f.read()

# Expand table newlines
table = os.environ["PKG_TABLE"].replace("\\n", "\n")

content = content.replace("{{AUR_USER}}", os.environ["AUR_USER"])
content = content.replace("{{AUR_EMAIL}}", os.environ["AUR_EMAIL"])
content = content.replace("{{PACKAGE_TABLE}}", table)
print(content, end="")
' > "${output}"
}

mapfile -t sorted_names < <(printf '%s\n' "${!dir_map[@]}" | sort)

table="| Package | Description | Upstream | Version | Build Status |\n| --- | --- | --- | --- | --- |"

for name in "${sorted_names[@]}"; do
	dir="${dir_map[${name}]}"
	pkgbuild="${dir}/PKGBUILD"
	if [[ ! -f "${pkgbuild}" ]]; then
		continue
	fi

	pkg_info="$(bash -c "source '${pkgbuild}'; printf '%s|%s|%s|%s' \"\${pkgname}\" \"\${pkgver}\" \"\${pkgdesc}\" \"\${_pkgname:-}\"")"
	pkg_name="${pkg_info%%|*}"
	rest="${pkg_info#*|}"
	pkg_version="${rest%%|*}"
	rest="${rest#*|}"
	pkg_desc="${rest%%|*}"
	upstream_name="${rest#*|}"

	if [[ -z "${upstream_name}" ]]; then
		upstream_name="${pkg_name}"
	fi

	pkg_desc="${pkg_desc//$'\n'/ }"
	pkg_desc="${pkg_desc//|/\\|}"
	upstream_name="${upstream_name//|/\\|}"

	build_status="N/A"
	BUILD_WORKFLOW=""
	UPSTREAM_NAME_OVERRIDE=""

	meta_file="${PKG_META_DIR}/${pkg_name}.env"
	if [[ -f "${meta_file}" ]]; then
		# shellcheck disable=SC1090
		source "${meta_file}"
	fi

	if [[ -n "${UPSTREAM_NAME_OVERRIDE:-}" ]]; then
		upstream_name="${UPSTREAM_NAME_OVERRIDE}"
	fi

	if [[ -n "${BUILD_WORKFLOW:-}" && -n "${GITHUB_SLUG}" ]]; then
		badge_url="https://img.shields.io/github/actions/workflow/status/${GITHUB_SLUG}/${BUILD_WORKFLOW}?branch=main&logo=github&label=build"
		link_url="https://github.com/${GITHUB_SLUG}/actions/workflows/${BUILD_WORKFLOW}"
		build_status="[![Build Status](${badge_url})](${link_url})"
	fi

	table+="\n| \`${pkg_name}\` | ${pkg_desc} | \`${upstream_name}\` | ${pkg_version} | ${build_status} |"
done

render_template "${TEMPLATE_EN}" "${OUTPUT_ROOT}"
render_template "${TEMPLATE_ZH}" "${OUTPUT_ZH}"

echo "README.md regenerated from template."
