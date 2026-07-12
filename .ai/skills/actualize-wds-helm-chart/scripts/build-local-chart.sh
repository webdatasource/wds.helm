#!/usr/bin/env bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="${1:-$(git -C "$script_dir" rev-parse --show-toplevel)}"
repo_root="$(CDPATH= cd -- "$repo_root" && pwd)"
chart_dir="$repo_root/charts/wds-helm-chart"
output_dir="${2:-$repo_root}"

command -v helm >/dev/null 2>&1 || {
  echo "helm is required" >&2
  exit 1
}

test -f "$chart_dir/Chart.yaml" || {
  echo "Helm chart not found: $chart_dir" >&2
  exit 1
}

mkdir -p "$output_dir"
output_dir="$(CDPATH= cd -- "$output_dir" && pwd)"
temp_dir="$(mktemp -d "$output_dir/.wds-helm-package.XXXXXX")"
trap 'rmdir "$temp_dir" 2>/dev/null || true' EXIT

helm package "$chart_dir" --destination "$temp_dir"

packages=("$temp_dir"/*.tgz)
if [[ ${#packages[@]} -ne 1 || ! -f "${packages[0]}" ]]; then
  echo "Expected exactly one packaged chart in $temp_dir" >&2
  exit 1
fi

artifact="$output_dir/$(basename -- "${packages[0]}")"
mv -f -- "${packages[0]}" "$artifact"

echo "Local chart package: $artifact"
shasum -a 256 "$artifact"
