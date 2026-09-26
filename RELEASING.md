# Releasing

A release is a `v*` tag on `master`. Installs clone the newest one (see `site/.well-known/agent-skills/build-ezkey/SKILL.md`). Nothing is built or uploaded: there are no binaries.

1. Bump `CFBundleShortVersionString` in `Resources/Info.plist` through a PR. `ci-gate` must pass. It includes `tests/site/review-checklist.test.ts`, which fails if the code no longer matches what the install skill tells agents to expect.
2. Tag the merge commit and push the tag:

   ```sh
   git switch master && git pull
   git tag v1.0.1 && git push origin v1.0.1
   ```

Only admins can create, move, or delete `v*` tags (`release-tags` ruleset). Never move a published tag: agents and users pin to it.
