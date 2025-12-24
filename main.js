const { app, BrowserWindow, ipcMain, clipboard, Menu } = require('electron');
const path = require('path');
const os = require('os');

let pty;
try {
  pty = require('node-pty');
} catch (e) {
  console.error('node-pty failed to load. You MUST run: npm install (postinstall runs electron-rebuild).');
  console.error(e);
}

const sessions = new Map();
let nextId = 1;

function createWindow() {
  app.commandLine.appendSwitch('disable-gpu-sandbox');
  app.commandLine.appendSwitch('no-sandbox');

  // Remove the menu bar
  Menu.setApplicationMenu(null);

  const win = new BrowserWindow({
    width: 1280,
    height: 760,
    backgroundColor: '#ffffff',
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      sandbox: false
    }
  });

  win.loadFile(path.join(__dirname, 'word-like.html'));
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  for (const [id, s] of sessions.entries()) {
    try { s.pty.kill(); } catch {}
    sessions.delete(id);
  }
  if (process.platform !== 'darwin') app.quit();
});

ipcMain.handle('pty:create', (event, opts) => {
  if (!pty) return { id: null, error: 'node-pty not available (run npm install)' };

  const win = BrowserWindow.fromWebContents(event.sender);
  const id = String(nextId++);

  const shell = (opts && opts.shell) || '/bin/bash';
  const cwd = (opts && opts.cwd) || process.env.HOME || os.homedir();
  const cols = (opts && opts.cols) || 80;
  const rows = (opts && opts.rows) || 24;

  const env = { ...process.env, TERM: 'xterm-256color', COLORTERM: 'truecolor' };

  const proc = pty.spawn(shell, ['-l'], {
    name: 'xterm-256color',
    cols,
    rows,
    cwd,
    env
  });

  sessions.set(id, { pty: proc, win });

  proc.onData((data) => {
    if (!win.isDestroyed()) win.webContents.send('pty:data', { id, data });
  });

  proc.onExit(() => {
    if (!win.isDestroyed()) win.webContents.send('pty:exit', { id });
    sessions.delete(id);
  });

  return { id, error: null };
});

ipcMain.on('pty:write', (_event, { id, data }) => {
  const s = sessions.get(String(id));
  if (!s) return;
  try { s.pty.write(data); } catch {}
});

ipcMain.on('pty:resize', (_event, { id, cols, rows }) => {
  const s = sessions.get(String(id));
  if (!s) return;
  try { s.pty.resize(Math.max(2, cols|0), Math.max(2, rows|0)); } catch {}
});

ipcMain.handle('clip:read', () => clipboard.readText());
ipcMain.handle('clip:write', (_e, text) => (clipboard.writeText(String(text ?? '')), true));
ipcMain.handle('clip:readSelection', () => {
  try { return clipboard.readText('selection'); } catch { return clipboard.readText(); }
});
ipcMain.handle('clip:writeSelection', (_e, text) => {
  try { clipboard.writeText(String(text ?? ''), 'selection'); } catch { clipboard.writeText(String(text ?? '')); }
  return true;
});
