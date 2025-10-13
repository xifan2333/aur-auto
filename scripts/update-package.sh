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

if ! declare -f pkg_get_update_params >/dev/null; then
	echo "pkg_get_update_params is not defined in ${UPSTREAM_HELPER}" >&2
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

read -r url filename pkgver hash_algo checksum <<<"$(pkg_get_update_params "${latest_version}")"
if [[ -z "${url}" || -z "${filename}" || -z "${pkgver}" || -z "${hash_algo}" || -z "${checksum}" ]]; then
	echo "pkg_get_update_params must return '<url> <filename> <pkgver> <hash_algo> <checksum>'" >&2
	exit 1
fi

pkg_update_files "${url}" "${filename}" "${pkgver}" "${hash_algo}" "${checksum}"

echo "Updated ${PKG_NAME} ${current_version} -> ${latest_version}"
