@echo off
SETLOCAL EnableDelayedExpansion

:: ============================================================
::  MK.TRADES — GitHub Sync Utility  v2.2
:: ============================================================

:: Self-locate: derive project dir from this script's own location
SET "PROJECT_DIR=%~dp0"
IF "%PROJECT_DIR:~-1%"=="\" SET "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

echo.
echo ===================================================
echo   MK.TRADES ^| GitHub Sync  v2.2
echo   Project : %PROJECT_DIR%
echo ===================================================
echo.

:: ── 1. Navigate to project root ──────────────────────────────
cd /d "%PROJECT_DIR%"
IF ERRORLEVEL 1 (
    echo [ERROR] Cannot navigate to project folder.
    echo         Expected: %PROJECT_DIR%
    pause & exit /b 1
)

:: ── 2. Verify Git is initialized ─────────────────────────────
IF NOT EXIST ".git" (
    echo [ERROR] No .git folder found. Run these first:
    echo.
    echo   cd /d "%PROJECT_DIR%"
    echo   git init
    echo   git remote add origin https://github.com/mkamareddine321/MK.TRADES-terminal-.git
    echo   git branch -M main
    echo   git add .
    echo   git commit -m "Initial commit"
    echo   git push -u origin main
    echo.
    pause & exit /b 1
)

:: ── 3. Detect current branch ─────────────────────────────────
FOR /F "tokens=*" %%B IN ('git rev-parse --abbrev-ref HEAD 2^>nul') DO SET "BRANCH=%%B"
IF "%BRANCH%"=="" SET "BRANCH=main"
echo [INFO] Branch: %BRANCH%
echo.

:: ── 4. Generate folder structure snapshot ─────────────────────
echo [INFO] Updating folder_structure.txt...
tree /f /a > folder_structure.txt 2>nul
IF ERRORLEVEL 1 (
    echo [WARN] tree command failed — skipping folder_structure.txt update.
) ELSE (
    echo [INFO] folder_structure.txt updated.
)
echo.

:: ── 5. Safety check: HARD-BLOCK data/model/state files ───────
echo [CHECK] Scanning for data/model/state files in pending changes...
git status --short > "%TEMP%\gstatus.txt" 2>&1

IF EXIST "%TEMP%\gleaks.txt" DEL "%TEMP%\gleaks.txt"

:: Group 1: Data file extensions
findstr /I "\.npy \.pth \.parquet \.pkl \.csv \.db \.sqlite \.h5 \.bin \.dat \.hst \.ipynb" "%TEMP%\gstatus.txt" >> "%TEMP%\gleaks.txt" 2>nul

:: Group 2: Runtime state JSON files
findstr /I "terminal_payload\.json signal_decisions\.json daily_signals\.json weekly_state\.json signal_lifecycle\.json" "%TEMP%\gstatus.txt" >> "%TEMP%\gleaks.txt" 2>nul
findstr /I "terminal_anchors\.json terminal_cones\.json terminal_calc_status\.json orchestrator_status\.json" "%TEMP%\gstatus.txt" >> "%TEMP%\gleaks.txt" 2>nul
findstr /I "orchestrator_log\.json portfolio_state\.json signal_validation_report\.json" "%TEMP%\gstatus.txt" >> "%TEMP%\gleaks.txt" 2>nul

:: Group 3: Data directories
findstr /I "data_library bands_data __pycache__ node_modules \.ipynb_checkpoints" "%TEMP%\gstatus.txt" >> "%TEMP%\gleaks.txt" 2>nul

:: Group 4: Log files
findstr /I "\.log" "%TEMP%\gstatus.txt" >> "%TEMP%\gleaks.txt" 2>nul

:: Check if anything was found
SET "DATA_LEAK=0"
IF EXIST "%TEMP%\gleaks.txt" (
    FOR %%A IN ("%TEMP%\gleaks.txt") DO IF %%~zA GTR 0 SET "DATA_LEAK=1"
)

IF "!DATA_LEAK!"=="1" (
    echo.
    echo  +==================================================+
    echo  ^|  BLOCKED: Data or state files in pending changes  ^|
    echo  +==================================================+
    echo.
    echo  Files that triggered the block:
    type "%TEMP%\gleaks.txt"
    echo.
    echo  Fix: update .gitignore or unstage these files:
    echo    git reset HEAD ^<filename^>
    echo.
    SET "OVERRIDE="
    set /p OVERRIDE="Type OVERRIDE to force (or press Enter to cancel): "
    IF /I NOT "!OVERRIDE!"=="OVERRIDE" (
        echo Sync cancelled. Fix .gitignore first.
        pause & exit /b 1
    )
    echo [WARN] Override accepted — proceeding at your own risk.
    echo.
)

:: ── 6. Pull remote changes FIRST (before staging anything) ───
echo [1/4] Pulling remote changes (%BRANCH%)...
git pull origin %BRANCH% --ff-only 2>nul
IF ERRORLEVEL 1 (
    echo [INFO] Fast-forward failed. Attempting rebase...
    git pull origin %BRANCH% --rebase --no-edit 2>nul
    IF ERRORLEVEL 1 (
        echo.
        echo [WARN] Pull failed. Possible causes:
        echo        - Merge conflict  (run: git status)
        echo        - No internet
        echo        - First push (remote empty — continuing)
        echo.
    )
)

:: ── 7. Stage all tracked files (.gitignore does the filtering) ──
echo [2/4] Staging changes...
git add .
IF ERRORLEVEL 1 (
    echo [ERROR] git add failed.
    pause & exit /b 1
)

:: Force-add folder_structure.txt (overrides .gitignore)
git add -f folder_structure.txt 2>nul

:: ── 8. Check if there's actually anything to commit ──────────
git diff --cached --quiet
IF NOT ERRORLEVEL 1 (
    echo.
    echo [INFO] Nothing to commit — working tree is clean.
    echo        No changes since last sync.
    echo.
    pause
    exit /b 0
)

:: ── 9. Show what will be committed ───────────────────────────
echo.
echo  Files being committed:
echo  ─────────────────────
git diff --cached --stat
echo.

:: ── 10. Commit with clean timestamp ─────────────────────────
FOR /F "usebackq delims=" %%I IN (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'" 2^>nul`) DO SET "TSTAMP=%%I"

IF "!TSTAMP!"=="" (
    FOR /F "tokens=2 delims==" %%I IN ('wmic os get localdatetime /value 2^>nul') DO SET "DT=%%I"
    IF DEFINED DT SET "TSTAMP=!DT:~0,4!-!DT:~4,2!-!DT:~6,2! !DT:~8,2!:!DT:~10,2!"
)
IF "!TSTAMP!"=="" SET "TSTAMP=unknown"

echo [3/4] Committing (Timestamp: %TSTAMP%)...
git commit -m "sync: %TSTAMP%"
IF ERRORLEVEL 1 (
    echo [ERROR] Commit failed.
    pause & exit /b 1
)

:: ── 11. Push to GitHub ───────────────────────────────────────
echo [4/4] Pushing to GitHub (%BRANCH%)...
git push origin %BRANCH%
IF ERRORLEVEL 1 (
    echo.
    echo [ERROR] Push failed. Possible causes:
    echo         - No internet connection
    echo         - Authentication issue (check GitHub credentials)
    echo         - Remote diverged (run: git pull origin %BRANCH%)
    pause & exit /b 1
)

:: ── Done ─────────────────────────────────────────────────────
echo.
echo ===================================================
echo   SYNC COMPLETE
echo   Branch : %BRANCH%
echo   Commit : %TSTAMP%
echo ===================================================
echo.
echo Press any key to close...
pause > nul