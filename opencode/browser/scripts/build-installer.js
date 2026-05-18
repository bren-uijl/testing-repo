#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const BROWSER_DIR = path.join(__dirname, '..');
const DIST_DIR = path.join(BROWSER_DIR, 'dist');

console.log('=== Nexus Browser Offline Installer Builder ===\n');

function run(cmd, options = {}) {
  console.log(`> ${cmd}`);
  try {
    execSync(cmd, { cwd: BROWSER_DIR, stdio: 'inherit', ...options });
  } catch (error) {
    console.error(`Command failed: ${cmd}`);
    process.exit(1);
  }
}

function checkPrerequisites() {
  console.log('[1/4] Checking prerequisites...');

  try {
    const nodeVersion = execSync('node --version', { encoding: 'utf8' }).trim();
    console.log(`  Node.js: ${nodeVersion}`);
  } catch {
    console.error('  ERROR: Node.js is required');
    process.exit(1);
  }

  try {
    const npmVersion = execSync('npm --version', { encoding: 'utf8' }).trim();
    console.log(`  npm: ${npmVersion}`);
  } catch {
    console.error('  ERROR: npm is required');
    process.exit(1);
  }

  const pkgPath = path.join(BROWSER_DIR, 'package.json');
  if (!fs.existsSync(pkgPath)) {
    console.error('  ERROR: package.json not found');
    process.exit(1);
  }

  const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
  console.log(`  Building: ${pkg.build.productName} v${pkg.version}`);
  console.log('');
}

function installDependencies() {
  console.log('[2/4] Installing dependencies...');
  run('npm install --production=false');
  console.log('');
}

function buildInstaller() {
  console.log('[3/4] Building offline installer...');

  const platform = process.platform;
  let buildCmd;

  if (platform === 'win32') {
    buildCmd = 'npm run build:offline';
  } else {
    console.log('  Note: Cross-compiling for Windows from non-Windows platform');
    console.log('  This requires wine and may not produce a working installer');
    buildCmd = 'npm run build:win';
  }

  run(buildCmd);
  console.log('');
}

function verifyOutput() {
  console.log('[4/4] Verifying output...');

  if (!fs.existsSync(DIST_DIR)) {
    console.error('  ERROR: dist directory not found');
    process.exit(1);
  }

  const files = fs.readdirSync(DIST_DIR);
  const installers = files.filter(f => f.endsWith('.exe') || f.endsWith('.msi'));

  if (installers.length === 0) {
    console.error('  WARNING: No installer files found in dist/');
    console.log('  Available files:');
    files.forEach(f => console.log(`    - ${f}`));
  } else {
    console.log('  Installer files created:');
    installers.forEach(f => {
      const stats = fs.statSync(path.join(DIST_DIR, f));
      const size = (stats.size / (1024 * 1024)).toFixed(2);
      console.log(`    - ${f} (${size} MB)`);
    });
  }

  console.log('');
  console.log('=== Build Complete ===');
  console.log(`Output directory: ${DIST_DIR}`);
  console.log('');
  console.log('To install, run the .exe file on a Windows machine.');
  console.log('The installer is fully offline and does not require internet access.');
}

checkPrerequisites();
installDependencies();
buildInstaller();
verifyOutput();
