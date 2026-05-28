@echo off
REM AutoAgent Interactive REPL for Windows
REM Usage: scripts\repl.bat

setlocal enabledelayedexpansion

set BINARY=
if exist "_build\native\release\build\src\main\main.exe" (
    set BINARY=_build\native\release\build\src\main\main.exe
) else if exist "_build\dist\autoagent.exe" (
    set BINARY=_build\dist\autoagent.exe
) else (
    echo Binary not found. Run 'make build-native' first.
    exit /b 1
)

echo.
echo   AutoAgent v0.1.0 REPL
echo   A lightweight MoonBit Agent runtime
echo.
echo   Commands:
echo     /help     - Show help
echo     /config   - Show configuration
echo     /clear    - Clear screen
echo     /quit     - Exit
echo     /run N    - Set max-steps to N
echo.

set MAX_STEPS=

:loop
set /p "input=❯ "
if "!input!"=="" goto loop

if "!input:~0,1!"=="/" (
    if "!input!"=="/help" (
        echo.
        echo   Commands:
        echo     /help     - Show this help
        echo     /config   - Show configuration
        echo     /clear    - Clear screen
        echo     /quit     - Exit
        echo     /run N    - Set max-steps to N
        echo.
    ) else if "!input!"=="/config" (
        !BINARY! --config
    ) else if "!input!"=="/clear" (
        cls
    ) else if "!input!"=="/quit" (
        echo Goodbye!
        exit /b 0
    ) else if "!input:~0,5!"=="/run " (
        set MAX_STEPS=!input:~5!
        echo Max-steps set to !MAX_STEPS!
    ) else (
        echo Unknown command: !input!
    )
    goto loop
)

echo.
echo Executing agent...
if defined MAX_STEPS (
    !BINARY! --max-steps !MAX_STEPS! "!input!"
) else (
    !BINARY! "!input!"
)
echo.
goto loop
