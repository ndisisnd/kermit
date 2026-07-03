#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const os = require('os');

const SRC = path.join(__dirname, '..');
const DEST = path.join(os.homedir(), '.claude', 'skills', 'kermit');

fs.mkdirSync(DEST, { recursive: true });
fs.copyFileSync(path.join(SRC, 'SKILL.md'), path.join(DEST, 'SKILL.md'));

const refsDir = path.join(SRC, 'refs');
if (fs.existsSync(refsDir)) {
  const destRefs = path.join(DEST, 'refs');
  fs.mkdirSync(destRefs, { recursive: true });
  for (const file of fs.readdirSync(refsDir)) {
    fs.copyFileSync(path.join(refsDir, file), path.join(destRefs, file));
  }
}

const prefFile = path.join(SRC, 'pref.json');
if (fs.existsSync(prefFile)) {
  fs.copyFileSync(prefFile, path.join(DEST, 'pref.json'));
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
