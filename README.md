# iq-mismatch-test-r

Test-only R package for DSW QA.

## Branches

| Branch            | Forces                         | How                                                              |
| ----------------- | ------------------------------ | ---------------------------------------------------------------- |
| `main`            | System IQ **MISMATCH**         | Imports `getopt (>= 1.20.4)`, upgrading the lock-pinned 1.20.3   |
| `missing-package` | System IQ **MISSING**          | `configure` uninstalls `getopt` while this package installs      |

## missing-package

- renv.lock pins `getopt` 1.20.3
- On install, `configure` runs `remove.packages("getopt")`, so System IQ reports
  `getopt (expected 1.20.3, installed none)` as `MISSING` and the build shows **Tests Failed**.
- To remove a different locked package, set `IQ_MISSING_PKG=<name>` in the build environment.
- If the target is not installed, `configure` does nothing and the install still succeeds.

Install source: `devanshyadav-sycamore/iq-mismatch-test-r`, ref `missing-package`.
