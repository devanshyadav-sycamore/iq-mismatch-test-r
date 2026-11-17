# iq-mismatch-test-r

Test-only R package for DSW QA. It forces a **System IQ MISSING** package on a non-PDV R exec config.

- The exec config installs `getopt` 1.20.3 (pinned in renv.lock / the package list)
- On install, `configure` runs `remove.packages("getopt")`, so System IQ reports
  `getopt (expected 1.20.3, installed none)` as `MISSING` and the build shows **Tests Failed**.
- To remove a different locked package, set `IQ_MISSING_PKG=<name>` in the build environment.
- If the target is not installed, `configure` does nothing and the install still succeeds.

Install source: `devanshyadav-sycamore/iq-mismatch-test-r`

The earlier MISMATCH variant (Imports `getopt (>= 1.20.4)`) is at commit `ff75682`.
