# iq-mismatch-test-r

Test-only R package for DSW QA. One install forces a **MISSING**, a **MISMATCH** and an
**UNEXPECTED** package in **System IQ** on a non-PDV R exec config, so a single build shows
all three in the test results.

| Status | What `configure` does | Default target | Override |
| --- | --- | --- | --- |
| `MISSING` | `remove.packages()` | `getopt` | `IQ_MISSING_PKG` |
| `MISMATCH` | reinstalls the package at another version | first package pinned in `/renv.lock` that CRAN has a different version of | `IQ_MISMATCH_PKG`, `IQ_MISMATCH_VERSION` (default: current CRAN version) |
| `UNEXPECTED` | installs an empty stub that no lock lists | `iqunexpectedtest` | `IQ_UNEXPECTED_PKG` |

## Use

1. In the exec config's `renv.lock`, pin `getopt` at `1.20.3` **and** at least one more package at
   a version older than CRAN's current one (for example `R6` `2.5.1`).
2. Add `devanshyadav-sycamore/iq-mismatch-test-r` as a GitHub package on the exec config.
3. Build. System IQ reports, for example:
   - `getopt` (expected 1.20.3, installed none) as `MISSING`
   - `R6` (expected 2.5.1, installed 2.6.1) as `MISMATCH`
   - `iqunexpectedtest` (installed 0.0.1) as `UNEXPECTED`

   The build shows **Tests Failed** because of the MISSING and MISMATCH packages. UNEXPECTED
   alone only fails PDV builds. `iqmismatchtest` and `remotes` also show as `UNEXPECTED`, because
   neither is in the lock.

## Notes

- The package must be installed **after** the packages it changes. That holds for `renv.lock`
  configs, where `renv::restore()` runs before the GitHub install. Packages from the exec
  config's custom package list are installed after it, so they are not seen.
- `renv.lock` is read from `/renv.lock`. Set `IQ_RENV_LOCK=<path>` if it is elsewhere.
- A step that cannot run (target not installed, no other CRAN version, no network) logs why
  with an `iqmismatchtest:` line in the build log. The install still succeeds.
- Packages are changed in the library they live in. The UNEXPECTED stub goes next to this package.

Earlier single-purpose variants: MISMATCH only (Imports `getopt (>= 1.20.4)`) at `ff75682`,
MISSING only at `9259da9`.
