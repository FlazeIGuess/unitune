#!/usr/bin/env node
/**
 * parse-changelog.js
 *
 * Parses CHANGELOG.md and pubspec.yaml to produce a JSON payload
 * consumed by the Cloudflare Worker's version endpoint.
 *
 * Usage (from unitune-app root):
 *   node scripts/parse-changelog.js
 *
 * Outputs: JSON to stdout, suitable for pipe or redirect.
 *
 * Expected CHANGELOG.md format per release block:
 *
 *   ## [1.2.3] - YYYY-MM-DD
 *
 *   ### What's New
 *   - [material_icon_name] Short Title — One sentence description.
 *   - [another_icon]       Another Title — Another description.
 *
 *   ### Added
 *   ...
 *
 * The "### What's New" section is the ONLY section parsed here.
 * All other sections (Added, Fixed, Changed, ...) are for developers.
 */

'use strict';

const fs = require('fs');
const path = require('path');

// ── Paths (relative to this script's location = scripts/) ─────────────────────
const ROOT = path.resolve(__dirname, '..');
const CHANGELOG_PATH = path.join(ROOT, 'CHANGELOG.md');
const PUBSPEC_PATH = path.join(ROOT, 'pubspec.yaml');

// ── Static values not derivable from CHANGELOG ────────────────────────────────
const UPDATE_URLS = {
  playstore: 'https://play.google.com/store/apps/details?id=de.unitune.unitune',
  github: 'https://github.com/FlazeIGuess/unitune/releases/latest',
  appstore: 'https://apps.apple.com/app/unitune/id0000000000',
};
const CHANGELOG_URL =
  'https://github.com/FlazeIGuess/unitune/blob/main/unitune-app/CHANGELOG.md';

// ── Helpers ────────────────────────────────────────────────────────────────────

function readFile(filePath) {
  if (!fs.existsSync(filePath)) {
    process.stderr.write(`Error: file not found: ${filePath}\n`);
    process.exit(1);
  }
  return fs.readFileSync(filePath, 'utf8');
}

/**
 * Parses "version: 1.2.3+45" from pubspec.yaml.
 * Returns { version: '1.2.3', build: 45 }.
 */
function parsePubspec(content) {
  const match = content.match(/^version:\s*(\d+\.\d+\.\d+)\+(\d+)/m);
  if (!match) {
    process.stderr.write('Error: could not parse version from pubspec.yaml\n');
    process.exit(1);
  }
  return { version: match[1], build: parseInt(match[2], 10) };
}

/**
 * Parses the first release block from CHANGELOG.md.
 *
 * Expected format:
 *   ## [1.2.3] - YYYY-MM-DD
 *   (optional blank lines)
 *   ### What's New
 *   - [icon] Title — Body
 *   ...
 *
 * Returns { version: string, whatsNew: Array<{icon, title, body}> }.
 */
function parseChangelog(content) {
  const lines = content.split('\n');

  // Find the first release heading: ## [x.y.z] - date
  const releaseHeaderRe = /^## \[(\d+\.\d+\.\d+)\]/;
  let releaseVersion = null;
  let inWhatsNew = false;
  const whatsNew = [];

  for (const line of lines) {
    // Detect release header (only process the FIRST one found)
    if (!releaseVersion) {
      const m = line.match(releaseHeaderRe);
      if (m) {
        releaseVersion = m[1];
      }
      continue;
    }

    // We are inside the first release block.
    // Stop when we hit the NEXT release block.
    if (line.match(releaseHeaderRe)) break;

    // Detect "### What's New" section start
    if (/^###\s+What's New/i.test(line)) {
      inWhatsNew = true;
      continue;
    }

    // Stop "What's New" collection when the next ### section begins
    if (inWhatsNew && /^###\s+/.test(line)) {
      inWhatsNew = false;
      continue;
    }

    // Parse a What's New bullet: - [icon] Title — Body
    if (inWhatsNew) {
      // Skip comment lines and blank lines
      if (/^\s*(<!--|$)/.test(line)) continue;

      // Match:  - [icon_name] Title — Body text
      const bulletRe = /^-\s+\[([^\]]+)\]\s+([^—–-]+)[—–-]+\s*(.+)$/u;
      const m = line.match(bulletRe);
      if (m) {
        whatsNew.push({
          icon: m[1].trim(),
          title: m[2].trim(),
          body: m[3].trim(),
        });
      } else if (/^-\s+/.test(line)) {
        // Fallback: plain bullet without icon — use a generic icon
        const text = line.replace(/^-\s+/, '').trim();
        whatsNew.push({ icon: 'new_releases', title: text, body: '' });
      }
    }
  }

  if (!releaseVersion) {
    process.stderr.write('Error: no release block found in CHANGELOG.md\n');
    process.exit(1);
  }

  return { version: releaseVersion, whatsNew };
}

// ── Main ───────────────────────────────────────────────────────────────────────

function main() {
  const changelog = readFile(CHANGELOG_PATH);
  const pubspec = readFile(PUBSPEC_PATH);

  const { version: pubspecVersion, build } = parsePubspec(pubspec);
  const { version: changelogVersion, whatsNew } = parseChangelog(changelog);

  // Warn if pubspec and CHANGELOG versions are out of sync.
  if (pubspecVersion !== changelogVersion) {
    process.stderr.write(
      `Warning: pubspec version (${pubspecVersion}) differs from CHANGELOG ` +
        `version (${changelogVersion}). Using pubspec version.\n`
    );
  }

  const payload = {
    latest_version: pubspecVersion,
    latest_build: build,
    force_update: false,
    min_supported_build: 1,
    whats_new: whatsNew,
    update_urls: UPDATE_URLS,
    changelog_url: CHANGELOG_URL,
  };

  process.stdout.write(JSON.stringify(payload, null, 2) + '\n');
}

main();
