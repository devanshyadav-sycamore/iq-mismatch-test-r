# iq-mismatch-test-r

Test-only R package for DSW QA. One install forces a **MISSING**, a **MISMATCH** and an
**UNEXPECTED** package in **System IQ** on a non-PDV R exec config, so a single build shows
all three in the test results.

| Status | What `configure` does | Default target | Override |
| --- | --- | --- | --- |
| `MISSING` | `remove.packages()` | `getopt` | `IQ_MISSING_PKG` |
| `MISMATCH` | reinstalls the package at another version | first package pinned in `/renv.lock` that CRAN has a different version of | `IQ_MISMATCH_PKG`, `IQ_MISMATCH_VERSION` (default: current CRAN version) |
| `UNEXPECTED` | installs an empty stub that no lock lists | `iqunexpectedtest` | `IQ_UNEXPECTED_PKG` |

Install source: `devanshyadav-sycamore/iq-mismatch-test-r`

## Use

1. Create an R exec config and paste this into its `renv.lock` (also in
   [`examples/renv.lock`](examples/renv.lock)). `getopt` is the MISSING target and `R6` is
   pinned below CRAN's current version, so it becomes the MISMATCH target.

   ```json
   {
     "R": {
       "Version": "4.4.1",
       "Repositories": [{ "Name": "CRAN", "URL": "https://cloud.r-project.org" }]
     },
     "Packages": {
       "R6": {
         "Package": "R6",
         "Version": "2.5.1",
         "Source": "Repository",
         "Repository": "CRAN"
       },
       "getopt": {
         "Package": "getopt",
         "Version": "1.20.3",
         "Source": "Repository",
         "Repository": "CRAN"
       }
     }
   }
   ```

   Set `R.Version` to the R version of the exec config's base image. To use other packages,
   pin `getopt` plus any package whose pinned version is older than CRAN's current one.

2. Add `devanshyadav-sycamore/iq-mismatch-test-r` as a GitHub package on the exec config.
3. Build. System IQ reports:

   | Package | Expected | Installed | Status |
   | --- | --- | --- | --- |
   | `getopt` | 1.20.3 | none | `MISSING` |
   | `R6` | 2.5.1 | 2.6.1 (CRAN's current version when you build) | `MISMATCH` |
   | `iqunexpectedtest` | none | 0.0.1 | `UNEXPECTED` |

   The build shows **Tests Failed** because of the MISSING and MISMATCH packages. UNEXPECTED
   alone only fails PDV builds. `iqmismatchtest` and `remotes` also show as `UNEXPECTED`,
   because neither is in the lock.

## Notes

- Pin at least two packages. With only `getopt` pinned there is nothing left to mismatch, so
  the MISMATCH step logs a hint and skips.
- The package must be installed **after** the packages it changes. That holds for `renv.lock`
  configs, where `renv::restore()` runs before the GitHub install. Packages from the exec
  config's custom package list are installed after it, so they are not seen.
- `renv.lock` is read from `/renv.lock`. Set `IQ_RENV_LOCK=<path>` if it is elsewhere.
- A step that cannot run (target not installed, no other CRAN version, no network) logs why
  with an `iqmismatchtest:` line in the build log. The install still succeeds.
- Packages are changed in the library they live in. The UNEXPECTED stub goes next to this package.

Earlier single-purpose variants: MISMATCH only (Imports `getopt (>= 1.20.4)`) at `ff75682`,
MISSING only at `9259da9`.
