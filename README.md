# iq-mismatch-test-r

Test-only R package for DSW QA. It forces a **System IQ version mismatch** on a non-PDV R exec config.

- renv.lock pins `getopt` 1.20.3
- GitHub Repo: `devanshyadav-sycamore/iq-mismatch-test-r`

Installing this package needs `getopt (>= 1.20.4)`, so it upgrades getopt and System IQ reports
`getopt (expected 1.20.3, found 1.20.4)` and the build shows **Tests Failed**.
