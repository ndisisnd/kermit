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

console.log(`kermit installed → ${DEST}`);
console.log('Use /kermit in any Claude Code session.');
