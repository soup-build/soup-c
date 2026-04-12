@echo off
SETLOCAL
SET RootDir=%~dp0

soup build code\extension\
soup run ..\soup\code\generate-test\ -args %RootDir%\code\run-tests.wren %RootDir%\out\wren\local\c\0.7.0\J_HqSstV55vlb-x6RWC_hLRFRDU\script\bundles.sml
if %ERRORLEVEL% NEQ  0 exit /B %ERRORLEVEL%