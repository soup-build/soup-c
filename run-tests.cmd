@echo off
SETLOCAL
SET RootDir=%~dp0

soup run ..\soup\code\generate-test\ -args %RootDir%\code\run-tests.wren %RootDir%\out\Wren\Local\C\0.5.1\J_HqSstV55vlb-x6RWC_hLRFRDU\script\bundles.sml
if %ERRORLEVEL% NEQ  0 exit /B %ERRORLEVEL%