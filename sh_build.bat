:: Shamus - perform a full build of program
@echo off

::-----------------------------------------------------------------------------------
set "PRG=Shamus.prg"
set "PRGHDR=prgheader.bin"

:: Compile main program
.\bin\acme.exe -l .\build\symbols -o .\build\main .\main.asm
if errorlevel 1 (
    powershell write-host -back Red Compiled with errors
    exit /b 1
)
powershell write-host -back Green Compiled ok

:: Add the 2 load address bytes for the PRG header (PRG header created using Notepad++ with hex editor plugin)
copy /b .\build\%PRGHDR%+.\build\main ".\prg\%PRG%" >nul
if errorlevel 1 (
    powershell write-host -back Red Failed to create program file
    exit /b 1
)

:: Binary file comparison for unexpanded version
fc.exe /b ".\prg\%PRG%" ".\prg\Shamus original.prg" && (
    powershell write-host -back Green Programs match
) || (
    powershell write-host -back Red Programs do not match
)
