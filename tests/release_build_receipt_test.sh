#!/usr/bin/env bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "${temporary_directory}"' EXIT

output_path="${temporary_directory}/release-build-receipt.json"
export GITHUB_REPOSITORY="rapidsai/workflows"
export GITHUB_RUN_ATTEMPT="1"
export GITHUB_RUN_ID="9876"
export GITHUB_SERVER_URL="https://github.com"
export GITHUB_SHA="0123456789012345678901234567890123456789"
export GITHUB_WORKFLOW_REF="rapidsai/workflows/.github/workflows/nightly-pipeline.yaml@refs/heads/main"
export RELEASE_BUILD_RUN_INFO='{"payloads":{"cudf":{"branch":"release/26.08","sha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},"cuvs":{"branch":"release/26.08","sha":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}}}'
export RELEASE_BUILD_NEEDS='{"cudf-build":{"result":"success","outputs":{"child_workflow_id":"123","child_workflow_url":"https://github.com/rapidsai/cudf/actions/runs/123","child_workflow_conclusion":"success"}},"cuvs-build":{"result":"failure","outputs":{"child_workflow_id":"456","child_workflow_url":"https://github.com/rapidsai/cuvs/actions/runs/456","child_workflow_conclusion":"failure"}},"cudf-tests":{"result":"success","outputs":{}}}'

bash "${repository_root}/.github/scripts/write-release-build-receipt.sh" "${output_path}"

jq -e '
  .schema_version == 1
  and .nightly.workflow_url == "https://github.com/rapidsai/workflows/actions/runs/9876"
  and .resolved_revisions == [
    {"branch":"release/26.08", "repository":"cudf", "sha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
    {"branch":"release/26.08", "repository":"cuvs", "sha":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}
  ]
  and (.build_runs | length) == 2
  and (.build_runs[] | select(.job_id == "cudf-build") | .workflow_id == "123")
  and (.build_runs[] | select(.job_id == "cuvs-build") | .result == "failure")
' "${output_path}" >/dev/null
