// scripts/ascii-guard.cjs
// Making Disciples Daily -- ASCII source guard
//
// Blocks any non-ASCII byte (> 0x7F) and any UTF-8 BOM in staged .ts/.tsx
// source files. Mirrors the BibleLessonSpark guard. Runs as a git pre-commit
// hook (see install instructions at the bottom) and is also invoked by
// deploy.ps1 before any push.
//
// Why: curly quotes, em dashes, and box-drawing characters pasted from chat or
// docs break the build pipeline and corrupt diffs. Use JavaScript escape
// sequences instead (e.g. \u2014 for an em dash).
//
// Usage:
//   node scripts/ascii-guard.cjs           -> scans staged .ts/.tsx files
//   node scripts/ascii-guard.cjs --all     -> scans every tracked .ts/.tsx file
//
// Exit code 0 = clean. Exit code 1 = at least one violation (commit blocked).

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const SCAN_ALL = process.argv.includes('--all');
const EXCLUDED = ['node_modules', 'dist', '.netlify', '.git'];

function isExcluded(p) {
  return EXCLUDED.some(function (dir) {
    return p.split(path.sep).indexOf(dir) !== -1;
  });
}

function listFiles() {
  let out;
  if (SCAN_ALL) {
    out = execSync('git ls-files "*.ts" "*.tsx"', { encoding: 'utf8' });
  } else {
    out = execSync('git diff --cached --name-only --diff-filter=ACM', {
      encoding: 'utf8',
    });
  }
  return out
    .split('\n')
    .map(function (s) { return s.trim(); })
    .filter(Boolean)
    .filter(function (f) { return /\.(ts|tsx)$/.test(f); })
    .filter(function (f) { return !isExcluded(f); })
    .filter(function (f) { return fs.existsSync(f); });
}

function scanFile(file) {
  const buf = fs.readFileSync(file);
  const violations = [];

  // BOM check (EF BB BF at byte 0)
  if (buf.length >= 3 && buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf) {
    violations.push({ line: 1, col: 1, kind: 'UTF-8 BOM', byte: '0xEFBBBF' });
  }

  let line = 1;
  let col = 0;
  for (let i = 0; i < buf.length; i++) {
    const b = buf[i];
    if (b === 0x0a) {
      line++;
      col = 0;
      continue;
    }
    col++;
    if (b > 0x7f) {
      violations.push({
        line: line,
        col: col,
        kind: 'non-ASCII byte',
        byte: '0x' + b.toString(16).toUpperCase().padStart(2, '0'),
      });
    }
  }
  return violations;
}

function main() {
  const files = listFiles();
  let total = 0;

  files.forEach(function (file) {
    const v = scanFile(file);
    if (v.length) {
      total += v.length;
      console.error('\nASCII GUARD: ' + file);
      v.slice(0, 20).forEach(function (item) {
        console.error(
          '  line ' + item.line + ', col ' + item.col + ': ' +
          item.kind + ' (' + item.byte + ')'
        );
      });
      if (v.length > 20) {
        console.error('  ... and ' + (v.length - 20) + ' more');
      }
    }
  });

  if (total > 0) {
    console.error(
      '\nCommit blocked: ' + total + ' non-ASCII / BOM issue(s) in ' +
      'source files.'
    );
    console.error(
      'Fix: replace literal Unicode with JS escape sequences ' +
      '(e.g. \\u2014 for em dash) and save UTF-8 without BOM.'
    );
    console.error(
      'Override only for a confirmed unavoidable encoding case: ' +
      'git commit --no-verify'
    );
    process.exit(1);
  }

  console.log('ASCII guard clean (' + files.length + ' file(s) scanned).');
  process.exit(0);
}

main();

// ---------------------------------------------------------------------------
// INSTALL AS A PRE-COMMIT HOOK (run once, from the repo root, in PowerShell):
//
//   $hook = ".git\hooks\pre-commit"
//   $body = "#!/bin/sh`nnode scripts/ascii-guard.cjs`nexit $?`n"
//   [System.IO.File]::WriteAllText(
//     (Resolve-Path .).Path + "\" + $hook,
//     $body,
//     [System.Text.UTF8Encoding]::new($false)
//   )
//
// On Windows, Git for Windows runs the hook via its bundled sh. No chmod needed.
// ---------------------------------------------------------------------------
