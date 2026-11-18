# Test-only: forces the three System IQ failure statuses. `configure` runs this
# during `R CMD INSTALL`, after renv has restored the packages pinned in renv.lock.
#
#   MISSING     removes IQ_MISSING_PKG (default: getopt)
#   MISMATCH    reinstalls IQ_MISMATCH_PKG at IQ_MISMATCH_VERSION (default: the
#               current CRAN version). Without IQ_MISMATCH_PKG, picks the first
#               package pinned in renv.lock that CRAN has a different version of.
#   UNEXPECTED  installs IQ_UNEXPECTED_PKG (default: iqunexpectedtest), a stub
#               that no renv.lock or base image lists
#
# renv.lock is read from IQ_RENV_LOCK (default: /renv.lock). A step that cannot do
# its job only logs why: the install must still succeed so the build reaches IQ.

repo <- "https://cloud.r-project.org"
lock <- Sys.getenv("IQ_RENV_LOCK", "/renv.lock")

say <- function(...) message("iqmismatchtest: ", ...)

setting <- function(name, default = NULL) {
  value <- Sys.getenv(name)
  if (nzchar(value)) value else default
}

lib_of <- function(pkg) {
  path <- find.package(pkg, quiet = TRUE)
  if (length(path) > 0) dirname(path[1])
}

installed_version <- function(pkg, lib) {
  tryCatch(as.character(packageVersion(pkg, lib.loc = lib)), error = function(e) NA_character_)
}

cran_versions <- function() {
  available <- tryCatch(available.packages(repos = repo, type = "source"), error = function(e) NULL)
  if (is.null(available)) return(character())
  setNames(available[, "Version"], rownames(available))
}

locked_versions <- function() {
  if (!file.exists(lock) || !requireNamespace("renv", quietly = TRUE)) return(character())
  unlist(lapply(renv::lockfile_read(lock)$Packages, function(p) p$Version))
}

# First locked package that is installed as locked and that CRAN has moved past.
pick_mismatch_pkg <- function(skip, latest) {
  locked <- locked_versions()
  for (pkg in sort(as.character(setdiff(names(locked), c("renv", skip))), method = "radix")) {
    lib <- lib_of(pkg)
    if (is.null(lib) || !identical(installed_version(pkg, lib), locked[[pkg]])) next
    if (!is.na(latest[pkg]) && latest[[pkg]] != locked[[pkg]]) return(pkg)
  }
}

install_cran_version <- function(pkg, version, lib) {
  tarball <- paste0(pkg, "_", version, ".tar.gz")
  # The current release is in contrib, older ones in Archive.
  for (url in file.path(repo, "src", "contrib", c(tarball, file.path("Archive", pkg, tarball)))) {
    suppressWarnings(try(install.packages(url, repos = NULL, type = "source", lib = lib, quiet = TRUE), silent = TRUE))
    if (identical(installed_version(pkg, lib), version)) return(TRUE)
  }
  FALSE
}

force_missing <- function(pkg) {
  lib <- lib_of(pkg)
  if (is.null(lib)) return(say("MISSING: ", pkg, " is not installed, nothing to remove"))
  remove.packages(pkg, lib = lib)
  say("MISSING: removed ", pkg, " from ", lib)
}

force_mismatch <- function(pkg, version, latest) {
  if (is.null(pkg)) {
    return(say("MISMATCH: no package pinned in ", lock, " has a different CRAN version, set IQ_MISMATCH_PKG"))
  }
  lib <- lib_of(pkg)
  if (is.null(lib)) return(say("MISMATCH: ", pkg, " is not installed, nothing to change"))
  current <- installed_version(pkg, lib)
  target <- if (is.null(version)) unname(latest[pkg]) else version
  if (is.na(target) || target == current) {
    return(say("MISMATCH: ", pkg, " ", current, " has no other version to install, set IQ_MISMATCH_VERSION"))
  }
  if (!install_cran_version(pkg, target, lib)) {
    return(say("MISMATCH: could not install ", pkg, " ", target, ", ", pkg, " stays at ", current))
  }
  say("MISMATCH: changed ", pkg, " from ", current, " to ", target, " in ", lib)
}

force_unexpected <- function(pkg, lib) {
  src <- file.path(tempdir(), pkg)
  dir.create(file.path(src, "R"), recursive = TRUE)
  writeLines(c(
    paste("Package:", pkg),
    "Version: 0.0.1",
    "Title: Throwaway Package For System IQ",
    "Description: Installed by iqmismatchtest so System IQ reports an UNEXPECTED package.",
    "License: GPL (>= 2)"
  ), file.path(src, "DESCRIPTION"))
  writeLines("# Intentionally empty", file.path(src, "NAMESPACE"))
  writeLines("# Intentionally empty", file.path(src, "R", "stub.R"))
  suppressWarnings(try(install.packages(src, repos = NULL, type = "source", lib = lib, quiet = TRUE), silent = TRUE))
  if (is.na(installed_version(pkg, lib))) return(say("UNEXPECTED: could not install ", pkg, " into ", lib))
  say("UNEXPECTED: installed ", pkg, " into ", lib)
}

missing_pkg <- setting("IQ_MISSING_PKG", "getopt")
latest <- cran_versions()
mismatch_pkg <- setting("IQ_MISMATCH_PKG", pick_mismatch_pkg(missing_pkg, latest))

if (identical(mismatch_pkg, missing_pkg)) {
  say("MISMATCH: ", mismatch_pkg, " is the MISSING target, pick a different IQ_MISMATCH_PKG")
} else {
  force_mismatch(mismatch_pkg, setting("IQ_MISMATCH_VERSION"), latest)
}
force_missing(missing_pkg)
# R CMD INSTALL puts its <lib>/00LOCK-<pkg>/00new staging dir first on the library path.
target_lib <- sub("/00LOCK-[^/]+/00new$", "", .libPaths()[1])
force_unexpected(setting("IQ_UNEXPECTED_PKG", "iqunexpectedtest"), target_lib)
