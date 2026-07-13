# workflows

This repository contains RAPIDS nightly build/test workflows.

## Release build collection

The nightly pipeline records the exact child build workflow runs it triggered
and uploads a `release-build-receipt` artifact. A release coordinator can use
that receipt as a coherent preferred set of immutable runs. If a selected
component failed or is absent, the release platform independently discovers a
successful run whose `head_sha` exactly matches that component's release-train
revision; it does not select the latest build of a branch. Product build
workflows opt in by adding the `rapidsai/shared-workflows`
`release-build-output.yaml` companion job for each artifact bundle; that job
supplies the primary-artifact name and the build-output manifest consumed by the
release platform.
