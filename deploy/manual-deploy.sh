#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1

usage() {
	cat <<'USAGE'
Usage: deploy/manual-deploy.sh stage|prod

Deploys the static Aparna landing page to the Aparna server.

Environment overrides:
  APARNA_SSH_TARGET   SSH target, defaults to aparna-srv-01
  STAGE_APP_DIR       Stage app directory, defaults to /opt/apartment-bot-stage
  PROD_APP_DIR        Production app directory, defaults to /opt/apartment-bot-prod
  LANDING_TARGET_DIR  Explicit target directory override
USAGE
}

deploy_env="${1:-}"
if [[ -z "${deploy_env}" || "${deploy_env}" == "-h" || "${deploy_env}" == "--help" ]]; then
	usage
	exit 0
fi

case "${deploy_env}" in
stage)
	app_dir="${STAGE_APP_DIR:-/opt/apartment-bot-stage}"
	;;
prod | production)
	deploy_env="prod"
	app_dir="${PROD_APP_DIR:-/opt/apartment-bot-prod}"
	;;
*)
	usage >&2
	exit 2
	;;
esac

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ssh_target="${APARNA_SSH_TARGET:-aparna-srv-01}"
target_dir="${LANDING_TARGET_DIR:-${app_dir}/web/landing}"
release_id="$(date -u +%Y%m%d%H%M%S)"
tmpdir="$(mktemp -d)"
remote_bundle="/tmp/aparna-landing-${deploy_env}-${release_id}.tar.gz"

cleanup() {
	rm -rf "${tmpdir}"
}
trap cleanup EXIT

echo "Packing Aparna landing assets"
tar --no-xattrs -czf "${tmpdir}/aparna-landing.tar.gz" \
	-C "${repo_root}" \
	index.html styles.css script.js assets

echo "Uploading bundle to ${ssh_target}:${remote_bundle}"
scp "${tmpdir}/aparna-landing.tar.gz" "${ssh_target}:${remote_bundle}"

echo "Deploying ${deploy_env} landing page to ${target_dir}"
ssh "${ssh_target}" \
	"REMOTE_BUNDLE='${remote_bundle}' TARGET_DIR='${target_dir}' bash -se" <<'REMOTE_SCRIPT'
set -euo pipefail

tmp_extract="$(mktemp -d)"
cleanup() {
	rm -rf "${tmp_extract}"
	rm -f "${REMOTE_BUNDLE}"
}
trap cleanup EXIT

tar -xzf "${REMOTE_BUNDLE}" -C "${tmp_extract}"
mkdir -p "${TARGET_DIR}"
find "${TARGET_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
cp -R "${tmp_extract}/." "${TARGET_DIR}/"
find "${TARGET_DIR}" -type d -exec chmod 755 {} +
find "${TARGET_DIR}" -type f -exec chmod 644 {} +
REMOTE_SCRIPT

echo "Done: ${deploy_env} landing -> ${target_dir}"
