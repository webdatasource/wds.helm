#!/usr/bin/env bash

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="${1:-$(git -C "$script_dir" rev-parse --show-toplevel)}"
repo_root="$(CDPATH= cd -- "$repo_root" && pwd)"
chart_dir="$repo_root/charts/wds-helm-chart"

command -v helm >/dev/null 2>&1 || {
  echo "helm is required" >&2
  exit 1
}

test -f "$chart_dir/Chart.yaml" || {
  echo "Helm chart not found: $chart_dir" >&2
  exit 1
}

cd "$repo_root"
helm unittest --strict -f 'tests/*-test.yaml' "$chart_dir"
