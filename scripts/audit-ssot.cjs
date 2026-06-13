// scripts/audit-ssot.cjs
// Making Disciples Daily -- SSOT and Frontend-Drives-Backend audit (READ-ONLY)
//
// Diagnostic only. Makes NO code changes. Writes findings to
// SSOT_AUDIT_REPORT.md in the repo root. Wired as: npm run audit-ssot
//
// Checks performed:
//   1. RULE #3 -- every key in ROUTES (src/constants/routes.ts) is referenced
//      as ROUTES.<KEY> in src/App.tsx, and no route path is hardcoded there.
//   2. RULE #13 -- no participant display string ("discipler", "disciple",
//      "apprentice", "group member") is hardcoded in a component; it must
//      resolve through src/constants/audienceConfig.ts.
//   3. Duplicated string-literal constants appearing across multiple files
//      (a heuristic for SSOT violations / values that should live in one place).
//
// Exit code is always 0 (diagnostic). The report records the findings.

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SRC_DIR = path.join(ROOT, 'src');
const REPORT_PATH = path.join(ROOT, 'SSOT_AUDIT_REPORT.md');
const STAMP = process.env.AUDIT_STAMP || 'see commit / session log';

const PARTICIPANT_TERMS = [
  'discipler',
  'disciple',
  'apprentice',
  'group member',
];

// --- file walking -----------------------------------------------------------
function walk(dir, acc) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  entries.forEach(function (e) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (e.name === 'node_modules' || e.name === 'dist') return;
      walk(full, acc);
    } else if (/\.(ts|tsx)$/.test(e.name)) {
      acc.push(full);
    }
  });
  return acc;
}

function rel(p) {
  return path.relative(ROOT, p).split(path.sep).join('/');
}

// Strip // line comments and /* */ block comments so audits ignore prose.
function stripComments(src) {
  return src
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/(^|[^:])\/\/[^\n]*/g, '$1');
}

// Find 1-based line number of an index in the original source.
function lineOf(src, index) {
  let line = 1;
  for (let i = 0; i < index && i < src.length; i++) {
    if (src[i] === '\n') line++;
  }
  return line;
}

// --- check 1: routes (Rule #3) ---------------------------------------------
function checkRoutes(findings) {
  const routesPath = path.join(SRC_DIR, 'constants', 'routes.ts');
  const appPath = path.join(SRC_DIR, 'App.tsx');

  if (!fs.existsSync(routesPath)) {
    findings.push({ rule: 'Rule #3', file: 'src/constants/routes.ts', line: 0,
      issue: 'routes.ts not found.', fix: 'Create the routes SSOT file.' });
    return;
  }
  if (!fs.existsSync(appPath)) {
    findings.push({ rule: 'Rule #3', file: 'src/App.tsx', line: 0,
      issue: 'App.tsx not found.', fix: 'Create App.tsx and wire ROUTES.' });
    return;
  }

  const routesSrc = fs.readFileSync(routesPath, 'utf8');
  const appSrc = fs.readFileSync(appPath, 'utf8');

  // Extract the ROUTES = { ... } object body.
  const block = routesSrc.match(/ROUTES\s*=\s*\{([\s\S]*?)\}\s*as const/);
  if (!block) {
    findings.push({ rule: 'Rule #3', file: 'src/constants/routes.ts', line: 0,
      issue: 'Could not locate a "ROUTES = { ... } as const" object.',
      fix: 'Declare routes as: export const ROUTES = { KEY: \'/path\' } as const;' });
    return;
  }

  const pairRe = /(\w+)\s*:\s*'([^']*)'/g;
  let m;
  let count = 0;
  while ((m = pairRe.exec(block[1])) !== null) {
    count++;
    const key = m[1];
    const routePath = m[2];

    if (!new RegExp('ROUTES\\.' + key + '\\b').test(appSrc)) {
      findings.push({ rule: 'Rule #3', file: 'src/App.tsx', line: 0,
        issue: 'Route ROUTES.' + key + " ('" + routePath + "') is not wired in App.tsx.",
        fix: 'Add a <Route path={ROUTES.' + key + '} .../> in the same pass.' });
    }

    // Hardcoded path literal in App.tsx (should use ROUTES.<KEY>).
    if (routePath !== '/' &&
        new RegExp("['\"]" + routePath.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + "['\"]").test(appSrc)) {
      findings.push({ rule: 'Rule #3', file: 'src/App.tsx', line: 0,
        issue: "Hardcoded path '" + routePath + "' in App.tsx.",
        fix: 'Reference ROUTES.' + key + ' instead of the literal path.' });
    }
  }

  findings._routeCount = count;
}

// --- check 2: hardcoded participant strings (Rule #13) ----------------------
// Rule #13 targets DISPLAY strings in COMPONENTS. The human-facing form is the
// CAPITALIZED standalone word ("Discipler", "Group Member"); lowercase keys
// passed to audienceTerm() and hyphenated brand prose ("disciple-makers") are
// correct usage and are not flagged. Scope: .tsx files only, excluding the
// audienceConfig SSOT itself.
function checkParticipantStrings(file, src, findings) {
  if (!/\.tsx$/.test(file)) return;
  if (rel(file).endsWith('constants/audienceConfig.ts')) return; // the SSOT itself
  const code = stripComments(src);

  PARTICIPANT_TERMS.forEach(function (term) {
    const display = term.replace(/\b\w/g, function (c) { return c.toUpperCase(); });
    const re = new RegExp('\\b' + display.replace(' ', '\\s+') + '\\b', 'g');
    let m;
    while ((m = re.exec(code)) !== null) {
      findings.push({ rule: 'Rule #13', file: rel(file), line: lineOf(code, m.index),
        issue: 'Possible hardcoded participant display term "' + display + '".',
        fix: 'Resolve via audienceTerm() from constants/audienceConfig.ts.' });
    }
  });
}

// --- check 3: duplicated string-literal constants ---------------------------
// Some tokens legitimately appear in more than one SSOT file because they belong
// to DISTINCT domains that the architecture deliberately keeps separate (so they
// must NOT import one another). These are not duplication to be deduped:
//   'discipler' -- an authz Role value in accessControl.ts AND a participant
//                  display-term key (ParticipantRole) in audienceConfig.ts.
//                  CLAUDE.md lists Access Control and Audience as two SSOT files.
// Keep this list as tight as possible; every entry needs a justification above.
const CROSS_DOMAIN_LITERALS = new Set([
  'discipler',
]);

function collectLiterals(file, src, registry) {
  if (/\.tsx$/.test(file)) return; // skip components (className noise)
  const code = stripComments(src);
  const re = /'([^'\n]{4,})'/g;
  let m;
  while ((m = re.exec(code)) !== null) {
    const val = m[1];
    if (/^[./@]/.test(val)) continue;            // import paths
    if (/\s/.test(val) && val.length > 40) continue; // prose-ish
    if (!registry[val]) registry[val] = new Set();
    registry[val].add(rel(file));
  }
}

function checkDuplicateLiterals(registry, findings) {
  Object.keys(registry).forEach(function (val) {
    if (CROSS_DOMAIN_LITERALS.has(val)) return; // legitimate distinct-domain token
    const files = Array.from(registry[val]);
    if (files.length > 1) {
      findings.push({ rule: 'SSOT', file: files.join(', '), line: 0,
        issue: "Literal '" + val + "' appears in " + files.length + ' files.',
        fix: 'Define once in the owning SSOT file and import it.' });
    }
  });
}

// --- report -----------------------------------------------------------------
function writeReport(findings, fileCount) {
  const lines = [];
  lines.push('# SSOT Audit Report -- Making Disciples Daily');
  lines.push('');
  lines.push('Generated by scripts/audit-ssot.cjs (READ-ONLY). Run: npm run audit-ssot');
  lines.push('Run stamp: ' + STAMP);
  lines.push('');
  lines.push('- Source files scanned: ' + fileCount);
  lines.push('- Routes checked (Rule #3): ' + (findings._routeCount || 0));
  lines.push('- Findings: ' + findings.length);
  lines.push('');

  if (findings.length === 0) {
    lines.push('## Result: CLEAN');
    lines.push('');
    lines.push('No SSOT, Rule #3, or Rule #13 violations detected.');
    lines.push('');
  } else {
    lines.push('## Findings');
    lines.push('');
    lines.push('| # | Rule | File | Line | Issue | Recommended fix |');
    lines.push('|---|------|------|------|-------|-----------------|');
    findings.forEach(function (f, i) {
      lines.push('| ' + (i + 1) + ' | ' + f.rule + ' | ' + f.file + ' | ' +
        (f.line || '-') + ' | ' + f.issue + ' | ' + f.fix + ' |');
    });
    lines.push('');
  }

  lines.push('## Checks performed');
  lines.push('');
  lines.push('1. Rule #3 -- every ROUTES key is wired in App.tsx; no hardcoded paths.');
  lines.push('2. Rule #13 -- no hardcoded participant strings in components.');
  lines.push('3. SSOT -- duplicated string-literal constants across files.');
  lines.push('');

  fs.writeFileSync(REPORT_PATH, lines.join('\n'), { encoding: 'utf8' });
}

// --- main -------------------------------------------------------------------
function main() {
  if (!fs.existsSync(SRC_DIR)) {
    console.error('audit-ssot: src/ not found. Nothing to scan.');
    process.exit(0);
  }

  const files = walk(SRC_DIR, []);
  const findings = [];
  const registry = {};

  checkRoutes(findings);

  files.forEach(function (file) {
    const src = fs.readFileSync(file, 'utf8');
    checkParticipantStrings(file, src, findings);
    collectLiterals(file, src, registry);
  });

  checkDuplicateLiterals(registry, findings);

  writeReport(findings, files.length);

  console.log('audit-ssot complete: ' + files.length + ' file(s) scanned, ' +
    findings.length + ' finding(s).');
  console.log('Report written to SSOT_AUDIT_REPORT.md');
  process.exit(0);
}

main();
