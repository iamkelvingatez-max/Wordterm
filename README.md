# WordTerm
![WordTerm demo](assets/demo/wordterm-demo-clean.gif)

WordTerm is an Electron terminal emulator that mimics the Microsoft Word UI. It embeds an xterm.js terminal inside a Word-like document surface and includes a File-style overlay for actions and tool launching.

## Current UI
- Main entry: `main.js` loads `word-like.html`.
- Chrome: titlebar, tabs, ribbon, and status bar styled like Word.
- Document area: a single page containing the xterm.js terminal.
- File overlay: terminal actions, Kali tool launcher, view/theme options, and session export.

## Features
- PTY-backed bash terminal via node-pty.
- Copy/paste + context menu.
- Command/file autocomplete with history.
- Font and theme controls.
- Quick tool launcher and session export.

## Run
```bash
npm install
npm start
```

## Desktop Launcher (Linux)
`npm install` will create a launcher in `~/.local/share/applications` and a desktop shortcut if your Desktop folder exists.  
You can re-run it any time with:
```bash
npm run install:desktop
```

## Build
The `build` config in `package.json` is ready for electron-builder. Install `electron-builder` if you want to package.

## Notes
- Backups are kept outside the repo and not tracked by Git.
- `legacy/index.html` remains as a legacy UI but is not loaded by default.
- Icons live in `assets/icons`, helper scripts in `scripts`, and the desktop file in `desktop`.
