@echo off

rem Script for exporting the files changed in the last commit of a hg repo to another hg repo as a patch so you can
rem commit the changes to the other repo too.
rem You can use this to publish changesets (like when an issue branch is merged) from a hg repo to another hg repo.

rem Usage: ExportLastCommitToAnotherHgRepo.bat HgRepo1Path HgRepo2Path

rem Note that on contrary to doing a hg archive exporting a patch like this will also remove files in the other repo
rem when they're removed in the original repo.

rem Taking two command line arguments. Below we cd to the git repo path because with relative paths --git-dir and 
rem --work-tree wouldn't work.
set hgRepo1Path=%1
set hgRepo2Path=%2

rem Replacing double quotes with empty string (i.e. removing double quotes) so if the path needs the quotes (due to
rem containing spaces) it won't mess up the path concatenation in hg export.
set hgRepo2Path=%hgRepo2Path:"=%

@echo on

hg export --output "%hgRepo2Path%\export.patch" --verbose --git -R %hgRepo1Path%
cd /D "%hgRepo2Path%"
hg import "export.patch" --verbose --similarity 80 --no-commit -R %hgRepo2Path%
del "export.patch"

cd "%~dp0%"