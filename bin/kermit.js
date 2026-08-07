#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const os = require('os');

// The skill body lives under skills/kermit/ so packagers ship only it, not the repo.
const SRC = path.join(__dirname, '..', 'skills', 'kermit');
// Claude Code reads user-level skills from ~/.claude/skills/; Codex reads them from
// ~/.agents/skills/ (its USER scope). Same body, different destination — mirrors
// install.sh's --claude / --codex / --all switch.
const CLAUDE_DEST = path.join(os.homedir(), '.claude', 'skills', 'kermit');
const CODEX_DEST = path.join(os.homedir(), '.agents', 'skills', 'kermit');

const args = process.argv.slice(2);
if (args.includes('-h') || args.includes('--help')) {
  console.log('Usage: kermit-msg [--claude | --codex | --all]');
  console.log(`  --claude  install for Claude Code at ${CLAUDE_DEST} (default)`);
  console.log(`  --codex   install for OpenAI Codex at ${CODEX_DEST}`);
  console.log('  --all     install for both');
  process.exit(0);
}
const wantAll = args.includes('--all');
const wantCodex = wantAll || args.includes('--codex');
// --claude stays the default so an argument-less run behaves exactly as before.
const wantClaude = wantAll || args.includes('--claude') || !wantCodex;

const targets = [];
if (wantClaude) targets.push(CLAUDE_DEST);
if (wantCodex) targets.push(CODEX_DEST);

// Recurse so any nested files are shipped, not just top-level ones.
const copyDir = (src, dest) => {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const from = path.join(src, entry.name);
    const to = path.join(dest, entry.name);
    if (entry.isDirectory()) copyDir(from, to);
    else fs.copyFileSync(from, to);
  }
};

for (const DEST of targets) {
  // Wipe any previous install so files retired or renamed in an upgrade don't linger.
  // The skill dir holds only shipped files — the per-repo runtime lives in each
  // project's kermit dir — so a full wipe is safe and matches this version exactly.
  fs.rmSync(DEST, { recursive: true, force: true });
  fs.mkdirSync(DEST, { recursive: true });
  fs.copyFileSync(path.join(SRC, 'SKILL.md'), path.join(DEST, 'SKILL.md'));

  const refsDir = path.join(SRC, 'refs');
  if (fs.existsSync(refsDir)) copyDir(refsDir, path.join(DEST, 'refs'));

  // Ship the agents/ dir (Codex skill declaration + the ready-to-copy subagent role).
  const agentsDir = path.join(SRC, 'agents');
  if (fs.existsSync(agentsDir)) copyDir(agentsDir, path.join(DEST, 'agents'));

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
}

console.log('');
console.log('kermit formats and runs git commits using Conventional Commits — emoji prefix,');
console.log('point-form file bodies, BREAKING CHANGE footer — and keeps CHANGELOG.md in sync.');
console.log('');

if (wantClaude) {
  console.log('Claude Code');
  console.log('→ Run "/kermit --init" in any local repo to initialise its preferences.');
  console.log(`→ Tailor kermit to your needs by editing ${CLAUDE_DEST}/SKILL.md.`);
  console.log('');
}

if (wantCodex) {
  console.log('Codex');
  console.log('→ Run "/kermit --init" in any local repo to initialise its preferences.');
  console.log(`→ Tailor kermit to your needs by editing ${CODEX_DEST}/SKILL.md.`);
  console.log(`→ Copy ${CODEX_DEST}/agents/kermit-agent.toml to .codex/agents/kermit.toml in a repo to make kermit spawnable as a subagent.`);
  console.log('');
  console.log("Add these two lines to your repo's AGENTS.md so Codex routes commits through kermit:");
  console.log('');
  console.log('  After completing a change, delegate the commit to the kermit skill / kermit subagent rather than committing ad hoc.');
  console.log('  Before merging or pushing to main/master, run `/kermit --release` (or spawn the kermit subagent in release mode) so the release ships user-facing notes.');
  console.log('');
}

console.log('\x1b[35mThank you JC ❤️\x1b[0m');
