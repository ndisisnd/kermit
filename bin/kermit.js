#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const os = require('os');

// The skill body lives under skills/kermit/ so packagers ship only it, not the repo.
const SRC = path.join(__dirname, '..', 'skills', 'kermit');
const DEST = path.join(os.homedir(), '.claude', 'skills', 'kermit');

// Wipe any previous install so files retired or renamed in an upgrade don't linger.
// The skill dir holds only shipped files — the per-repo runtime lives in each
// project's .claude/kermit/ — so a full wipe is safe and matches this version exactly.
fs.rmSync(DEST, { recursive: true, force: true });
fs.mkdirSync(DEST, { recursive: true });
fs.copyFileSync(path.join(SRC, 'SKILL.md'), path.join(DEST, 'SKILL.md'));

const refsDir = path.join(SRC, 'refs');
if (fs.existsSync(refsDir)) {
  const destRefs = path.join(DEST, 'refs');
  // Recurse so any nested ref files are shipped, not just top-level files.
  const copyDir = (src, dest) => {
    fs.mkdirSync(dest, { recursive: true });
    for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
      const from = path.join(src, entry.name);
      const to = path.join(dest, entry.name);
      if (entry.isDirectory()) copyDir(from, to);
      else fs.copyFileSync(from, to);
    }
  };
  copyDir(refsDir, destRefs);
}

// Ship the hooks/ dir (e.g. the merge-to-main guard) and keep the scripts executable.
const hooksDir = path.join(SRC, 'hooks');
if (fs.existsSync(hooksDir)) {
  const destHooks = path.join(DEST, 'hooks');
  fs.mkdirSync(destHooks, { recursive: true });
  for (const entry of fs.readdirSync(hooksDir, { withFileTypes: true })) {
    if (!entry.isFile()) continue;
    const to = path.join(destHooks, entry.name);
    fs.copyFileSync(path.join(hooksDir, entry.name), to);
    if (entry.name.endsWith('.sh')) { try { fs.chmodSync(to, 0o755); } catch {} }
  }
}

// pref.json (config) and state.json (volatile runtime state) ship as templates.
for (const tmpl of ['pref.json', 'state.json']) {
  const src = path.join(SRC, tmpl);
  if (fs.existsSync(src)) fs.copyFileSync(src, path.join(DEST, tmpl));
}

console.log(`Done. Installed → ${DEST}`);
console.log('');
console.log('kermit formats and runs git commits using Conventional Commits — emoji prefix,');
console.log('point-form file bodies, BREAKING CHANGE footer — and keeps CHANGELOG.md in sync.');
console.log('');
console.log('→ Run "/kermit --init" in any local repo to initialise its preferences.');
console.log(`→ Tailor kermit to your needs by editing ${DEST}/SKILL.md.`);
console.log('');
console.log('\x1b[35mThank you JC ❤️\x1b[0m');
