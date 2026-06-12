# deploy.ps1
# Making Disciples Daily -- deploy script
#
# Enforces the deploy sequence from CLAUDE.md:
#   1. main branch only (Rule #9)
#   2. ASCII guard clean on staged source (Rule #12)
#   3. npm run build clean -- zero errors (Rule #5)
#   4. commit + push to main (Netlify auto-deploys)
#
# This script does NOT bypass the localhost hold. Lynn must have already
# verified on localhost in a new browser tab and given explicit approval before
# this is run. The script will not start a dev server for you.
#
# Usage (PowerShell, from repo root):
#   powershell -ExecutionPolicy Bypass -File .\deploy.ps1 "FEATURE: short message"
# or, if execution policy already allows:
#   .\deploy.ps1 "FEATURE: short message"
#
# Commit message format (CLAUDE.md): [CATEGORY]: Brief description
#   Categories: SSOT, FIX, FEATURE, REFACTOR, SECURITY, DOCS

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Message
)

$ErrorActionPreference = "Stop"

function Fail($text) {
    Write-Host ""
    Write-Host "DEPLOY ABORTED: $text" -ForegroundColor Red
    exit 1
}

Write-Host "Making Disciples Daily -- deploy" -ForegroundColor Cyan
Write-Host "--------------------------------"

# --- Step 1: branch must be main (Rule #9) -------------------------------
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne "main") {
    Fail "current branch is '$branch'. MDD deploys from 'main' only. Switch to main first."
}
Write-Host "[1/5] Branch check: on main." -ForegroundColor Green

# --- Step 2: stage everything, then run the ASCII guard on staged files ---
git add -A

Write-Host "[2/5] ASCII guard on staged source..."
node scripts/ascii-guard.cjs
if ($LASTEXITCODE -ne 0) {
    Fail "ASCII guard found non-ASCII / BOM issues. Fix them (use JS escapes like \u2014) and re-run."
}
Write-Host "[2/5] ASCII guard clean." -ForegroundColor Green

# --- Step 3: clean build required (Rule #5) ------------------------------
Write-Host "[3/5] npm run build (must be clean)..."
npm run build
if ($LASTEXITCODE -ne 0) {
    Fail "build failed. Nothing is committed or pushed. Fix the build and re-run."
}
Write-Host "[3/5] Build clean." -ForegroundColor Green

# --- Step 4: confirm there is something to commit ------------------------
$pending = git status --porcelain
if ([string]::IsNullOrWhiteSpace($pending)) {
    Write-Host "[4/5] Nothing to commit -- working tree clean. Nothing to deploy." -ForegroundColor Yellow
    exit 0
}
Write-Host "[4/5] Changes staged for commit." -ForegroundColor Green

# --- Step 5: commit + push (Netlify auto-deploys from main) --------------
Write-Host "[5/5] Committing and pushing to main..."
git commit -m "$Message"
if ($LASTEXITCODE -ne 0) {
    Fail "git commit failed. (If a hook reported a BOM/encoding issue that cannot be resolved, see CLAUDE.md before using --no-verify.)"
}

git push origin main
if ($LASTEXITCODE -ne 0) {
    Fail "git push failed. The commit exists locally but did not reach origin/main. Resolve and push manually."
}

Write-Host ""
Write-Host "Deployed. Netlify will build and publish from main." -ForegroundColor Green
Write-Host "Commit message: $Message"
Write-Host ""
Write-Host "Session-end reminder: update PROJECT_MASTER.md and re-upload it to the Claude.ai project." -ForegroundColor Cyan
