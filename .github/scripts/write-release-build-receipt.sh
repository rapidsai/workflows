#!/usr/bin/env bash
# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

set -euo pipefail

output_path="${1:?usage: write-release-build-receipt.sh OUTPUT_PATH}"

require_nonempty() {
  local name="$1"
  local value="$2"
  if [[ -z "${value}" ]]; then
    echo "${name} must not be empty" >&2
    exit 1
  fi
}

require_nonempty "RELEASE_BUILD_NEEDS" "${RELEASE_BUILD_NEEDS:-}"
require_nonempty "RELEASE_BUILD_RUN_INFO" "${RELEASE_BUILD_RUN_INFO:-}"
require_nonempty "GITHUB_REPOSITORY" "${GITHUB_REPOSITORY:-}"
require_nonempty "GITHUB_RUN_ID" "${GITHUB_RUN_ID:-}"
require_nonempty "GITHUB_SERVER_URL" "${GITHUB_SERVER_URL:-}"

jq -e 'type == "object" and (.payloads | type == "object")' <<<"${RELEASE_BUILD_RUN_INFO}" >/dev/null
jq -e 'type == "object"' <<<"${RELEASE_BUILD_NEEDS}" >/dev/null

jq -n \
  --arg repository "${GITHUB_REPOSITORY}" \
  --arg run_attempt "${GITHUB_RUN_ATTEMPT:-}" \
  --arg run_id "${GITHUB_RUN_ID}" \
  --arg server_url "${GITHUB_SERVER_URL}" \
  --arg sha "${GITHUB_SHA:-}" \
  --arg workflow_ref "${GITHUB_WORKFLOW_REF:-}" \
  --argjson build_needs "${RELEASE_BUILD_NEEDS}" \
  --argjson run_info "${RELEASE_BUILD_RUN_INFO}" \
  '
  {
    schema_version: 1,
    producer: "rapids-nightly-pipeline",
    nightly: {
      repository: $repository,
      workflow_url: "\($server_url)/\($repository)/actions/runs/\($run_id)",
      run_id: $run_id,
      run_attempt: $run_attempt,
      sha: $sha,
      workflow_ref: $workflow_ref
    },
    resolved_revisions: [
      $run_info.payloads
      | to_entries[]
      | {
          repository: .key,
          branch: .value.branch,
          sha: .value.sha
        }
    ],
    build_runs: [
      $build_needs
      | to_entries[]
      | select(.value.outputs.child_workflow_id | type == "string" and length > 0)
      | {
          job_id: .key,
          result: .value.result,
          workflow_id: .value.outputs.child_workflow_id,
          workflow_url: .value.outputs.child_workflow_url,
          conclusion: .value.outputs.child_workflow_conclusion
        }
    ]
  }
  ' | jq -S . >"${output_path}"

jq -e '
  .schema_version == 1
  and .producer == "rapids-nightly-pipeline"
  and (.nightly.repository | type == "string" and length > 0)
  and (.resolved_revisions | type == "array")
  and (.build_runs | type == "array")
' "${output_path}" >/dev/null
