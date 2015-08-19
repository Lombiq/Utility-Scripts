@echo off

rem Script for copying the files changed in the last commit of a hg repo to another folder (like a git repo's folder so 
rem you can commit the changes to git too).
rem You can use this to publish changesets (like when an issue branch is merged) from a hg repo to a git (or another hg) repo.

rem Usage: ArchiveLastCommitToFolder.bat HgRepoPath ToDirectoryPath

rem Note that with this only changed (and added) files will be copied over, but if a file was removed this change won't 
rem be reflected in the target directory.

rem Taking two command line arguments.
set hgRepoPath=%1
set toDirectoryPath=%2

@echo on

hg archive -I "set:added() or modified()" -S -r tip -t files "%toDirectoryPath%" -R "%hgRepoPath%"