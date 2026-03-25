# _gen_tree.ps1 — Smart folder structure generator for MK.TRADES
# Called by sync_project.bat — do not rename or move
# Generates a compact folder_structure.txt excluding heavy/generated dirs

$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }
Set-Location $root

# Directories to SKIP entirely (won't recurse into)
$excludeDirs = @(
    'node_modules', '.git', '__pycache__',
    'data_library', 'bands_data', 'logs',
    'calibration_reports', 'backtest_results', 'reports',
    '.venv', 'venv', 'env', 'build', 'dist', '.eggs',
    '.ipynb_checkpoints', '.vscode', '.idea'
)

# File extensions to SKIP
$excludeExt = @(
    '.pyc', '.pyo', '.pyd', '.log',
    '.parquet', '.pkl', '.h5', '.db', '.sqlite', '.sqlite3',
    '.bin', '.dat', '.hst', '.npy', '.pth', '.feather'
)

# Files to skip by name
$excludeFiles = @(
    '.DS_Store', 'Thumbs.db', 'Desktop.ini',
    'package-lock.json', '.package-lock.json'
)

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# MK.TRADES - Project Structure (smart filtered)")
$lines.Add("# Excluded dirs: $($excludeDirs -join ', ')")
$lines.Add("# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$lines.Add("")
$lines.Add("D:\")

function Show-Tree {
    param([string]$Path, [string]$Indent)

    $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | Where-Object {
        $name = $_.Name
        if ($_.PSIsContainer) {
            return ($excludeDirs -notcontains $name)
        } else {
            $ext = $_.Extension.ToLower()
            return (($excludeExt -notcontains $ext) -and ($excludeFiles -notcontains $name))
        }
    } | Sort-Object { -not $_.PSIsContainer }, Name

    $count = $items.Count
    $i = 0

    foreach ($item in $items) {
        $i++
        $isLast = ($i -eq $count)
        $branch = if ($isLast) { "+-- " } else { "|-- " }
        $nextIndent = if ($isLast) { "    " } else { "|   " }

        if ($item.PSIsContainer) {
            # Count trackable files inside (excluding filtered stuff)
            $inner = Get-ChildItem -Path $item.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
                $n = $_.Name; $e = $_.Extension.ToLower(); $p = $_.FullName
                $dirSkip = $false
                foreach ($d in $excludeDirs) {
                    if ($p -match "[\\/]$([regex]::Escape($d))[\\/]") { $dirSkip = $true; break }
                }
                (-not $dirSkip) -and ($excludeExt -notcontains $e) -and ($excludeFiles -notcontains $n)
            }
            $fileCount = @($inner).Count
            $lines.Add("$Indent$branch$($item.Name)/  ($fileCount files)")
            Show-Tree -Path $item.FullName -Indent "$Indent$nextIndent"
        } else {
            $lines.Add("$Indent$branch$($item.Name)")
        }
    }
}

Show-Tree -Path $root -Indent ""

# Write output
$lines | Out-File -FilePath (Join-Path $root "folder_structure.txt") -Encoding UTF8 -Force

Write-Host "[OK] folder_structure.txt: $($lines.Count) lines (was 47K+ unfiltered)"
