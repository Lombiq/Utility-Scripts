@echo off

rem Script for exporting the files changed in the last commit of a hg repo to a git repo as a patch so you can commit
rem the changes to git too.
rem You can use this to publish changesets (like when an issue branch is merged) from a hg repo to a git repo.

rem Usage: ExportLastCommitToGit.bat HgRepoPath GitRepoPath

rem Note that on contrary to doing a hg archive exporting a patch like this will also remove files in the git repo
rem when they're removed in the hg repo.

rem Taking two command line arguments. Below we cd to the git repo path because with relative paths --git-dir and 
rem --work-tree wouldn't work.
set hgRepoPath=%1
set gitRepoPath=%2

rem Replacing double quotes with empty string (i.e. removing double quotes) so if the path needs the quotes (due to
rem containing spaces) it won't mess up the path concatenation in hg export.
set gitRepoPath=%gitRepoPath:"=%

@echo on

hg export --output "%gitRepoPath%\export.patch" --verbose --git -R %hgRepoPath%
cd /D "%gitRepoPath%"
git apply "export.patch" --3way --whitespace=fix
del "export.patch"

cd "%~dp0%"