## Submission

This is the first submission of DelphiR, a package for the statistical
analysis of Delphi studies.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Test environments

* Local: Ubuntu 24.04, R 4.3.3
* GitHub Actions: Windows (release, devel), macOS (release), Ubuntu 24.04
  (devel, release, oldrel-1)
* win-builder (devel)

## Notes for the reviewers

* Functions that write files (`delphi_report()` and `delphi_template()`)
  require an explicit path; examples, tests and the vignette write only to
  `tempdir()`.
* Examples that render reports are wrapped in `\donttest{}`, because they
  require Pandoc and take a few seconds.
