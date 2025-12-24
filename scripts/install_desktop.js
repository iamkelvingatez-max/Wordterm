#!/usr/bin/env node
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

function log(msg) {
  console.log(`[wordterm] ${msg}`);
}

function warn(msg) {
  console.warn(`[wordterm] ${msg}`);
}

function getDesktopDir(home) {
  const xdg = path.join(home, '.config', 'user-dirs.dirs');
  try {
    if (fs.existsSync(xdg)) {
      const content = fs.readFileSync(xdg, 'utf8');
      const match = content.match(/^XDG_DESKTOP_DIR=(.*)$/m);
      if (match && match[1]) {
        let value = match[1].trim();
        value = value.replace(/^"|"$/g, '');
        value = value.replace('$HOME', home);
        if (value) return value;
      }
    }
  } catch {}
  return path.join(home, 'Desktop');
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function safeCopy(src, dest) {
  try {
    fs.copyFileSync(src, dest);
    return true;
  } catch (err) {
    warn(`Failed to copy ${src} -> ${dest}: ${err.message}`);
    return false;
  }
}

function main() {
  if (process.platform !== 'linux') {
    log('Desktop install skipped (non-Linux).');
    return;
  }

  const home = os.homedir();
  if (!home) {
    warn('Desktop install skipped (no home directory).');
    return;
  }

  const root = path.resolve(__dirname, '..');
  const templatePath = path.join(root, 'desktop', 'wordterm.desktop');
  const iconSrc = path.join(root, 'assets', 'icons', 'icon.png');

  if (!fs.existsSync(templatePath)) {
    warn(`Desktop template missing: ${templatePath}`);
    return;
  }
  if (!fs.existsSync(iconSrc)) {
    warn(`Icon missing: ${iconSrc}`);
    return;
  }

  const execPath = path.join(root, 'node_modules', '.bin', 'electron');
  const execCmd = fs.existsSync(execPath) ? `${execPath} ${root}` : `electron ${root}`;

  const iconDir = path.join(home, '.local', 'share', 'icons', 'hicolor', '512x512', 'apps');
  const iconDest = path.join(iconDir, 'wordterm.png');
  try {
    ensureDir(iconDir);
    safeCopy(iconSrc, iconDest);
  } catch {}

  let desktopContent = fs.readFileSync(templatePath, 'utf8');
  desktopContent = desktopContent.replace(/^Exec=.*$/m, `Exec=${execCmd}`);
  desktopContent = desktopContent.replace(/^Icon=.*$/m, 'Icon=wordterm');

  const appDir = path.join(home, '.local', 'share', 'applications');
  try {
    ensureDir(appDir);
    const appPath = path.join(appDir, 'wordterm.desktop');
    fs.writeFileSync(appPath, desktopContent, { mode: 0o755 });
    fs.chmodSync(appPath, 0o755);
    log(`Installed launcher: ${appPath}`);

    const desktopDir = getDesktopDir(home);
    if (desktopDir && fs.existsSync(desktopDir)) {
      const desktopPath = path.join(desktopDir, 'wordterm.desktop');
      fs.writeFileSync(desktopPath, desktopContent, { mode: 0o755 });
      fs.chmodSync(desktopPath, 0o755);
      log(`Installed desktop shortcut: ${desktopPath}`);

      try {
        execFileSync('gio', ['set', desktopPath, 'metadata::trusted', 'true']);
      } catch {}
    }
  } catch (err) {
    warn(`Failed to install launcher: ${err.message}`);
  }
}

try {
  main();
} catch (err) {
  warn(`Desktop install failed: ${err.message}`);
}
