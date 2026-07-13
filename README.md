# workflows

This repository contains RAPIDS nightly build/test workflows.

## Release build collection

The nightly pipeline records the exact child build workflow runs it triggered
and uploads a `release-build-receipt` artifact. A release coordinator uses that
receipt to collect build content from those immutable runs rather than searching
for a later "latest passing" workflow. Product build workflows opt in by adding
the `rapidsai/shared-workflows` `release-build-output.yaml` companion job for
each artifact bundle; that job supplies the primary-artifact name and the
build-output manifest consumed by the release platform.
