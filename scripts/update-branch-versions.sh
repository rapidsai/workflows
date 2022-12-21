#!/bin/bash
# Script to update the RAPIDS and ucx-py branch versions
# throughout our workflow YAML files.
# Usage (from project root dir):
#   ./scripts/update-branch-versions.sh 23.02
set -euo pipefail

NEW_BRANCH_VERSION=$1
RAPIDS_BRANCH_PATTERN=[0-9]{2}.[0-9]{2}
UCX_PY_BRANCH_PATTERN=0.[0-9]{2}

if [[ ! "${NEW_BRANCH_VERSION}" =~ ^${RAPIDS_BRANCH_PATTERN}$ ]]; then
  echo "Input argument: ${NEW_BRANCH_VERSION}"
  echo "Error: Ensure input argument matches \"^${RAPIDS_BRANCH_PATTERN}$\" RegEx (e.g. \"23.02\")."
  exit 1
fi

UCX_PY_VERSION=$(curl -s "https://version.gpuci.io/rapids/${NEW_BRANCH_VERSION}")

if [[ ! "${UCX_PY_VERSION}" =~ ^${UCX_PY_BRANCH_PATTERN}$ ]]; then
  echo "UCX_PY_VERSION: ${UCX_PY_VERSION}"
  echo "Error: UCX_PY_VERSION does not match \"^${UCX_PY_BRANCH_PATTERN}$\" RegEx (e.g. \"0.30\")."
  exit 1
fi


echo "Replacing RAPIDS branch versions"
sed -ri \
  "s/branch-${RAPIDS_BRANCH_PATTERN}/branch-${NEW_BRANCH_VERSION}/g" \
  .github/workflows/{nightly,pip-wheels}-pipeline.yaml

echo "Replacing ucx-py branch versions"
sed -ri \
  "s/branch-${UCX_PY_BRANCH_PATTERN}/branch-${UCX_PY_VERSION}/g" \
  .github/workflows/{nightly,pip-wheels}-pipeline.yaml
