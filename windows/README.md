# WordTerm CMD

A stealth Windows CMD terminal emulator disguised as Microsoft Word. Perfect for privacy-focused users who want a professional-looking terminal interface.

![WordTerm CMD](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 🎭 **Stealth Design** - Looks exactly like Microsoft Word
- 💻 **Full CMD Terminal** - Complete Windows Command Prompt with PTY support
- 🎨 **Multiple Themes** - Light, Dark, Matrix, and Hacker themes
- ⚡ **Smart Autocomplete** - Command suggestions for common Windows tools
- 📋 **Right-Click Menu** - Easy copy/paste with context menu
- 🔧 **Windows Tools** - Quick launcher for ipconfig, netstat, ping, and more
- 💾 **Session Export** - Save your command history and terminal output
- 🎯 **Customizable Avatar** - Personalize with your initials

## Screenshots

The app features a complete Microsoft Word interface with ribbon controls and tabs, while hiding a fully functional Windows CMD terminal inside the document area.

## Installation

### Prerequisites

- **Node.js** (v14 or higher) - [Download here](https://nodejs.org/)
- **Windows OS** - Required for CMD functionality
- **Git** (optional) - For cloning the repository

### Quick Start

1. **Download or Clone**
   ```bash
   git clone https://github.com/yourusername/wordterm-cmd.git
   cd wordterm-cmd
   ```

   Or download and extract the ZIP file.

2. **Install Dependencies**
   ```bash
   npm install
   ```

   This will install:
   - Electron (desktop framework)
   - xterm.js (terminal emulator)
   - node-pty (terminal process support)

3. **Run the Application**
   ```bash
   npm start
   ```

That's it! WordTerm CMD should now be running.

### Troubleshooting

If you encounter issues during installation:

1. **"node-pty build failed"**
   - Install Windows Build Tools:
     ```bash
     npm install --global windows-build-tools
     ```
   - Then run `npm install` again

2. **"Electron failed to install"**
   - Clear npm cache:
     ```bash
     npm cache clean --force
     npm install
     ```

3. **Terminal not responding**
   - Click anywhere in the white page area to focus the terminal
   - Try hovering your mouse over the terminal area

4. **Missing dependencies**
   - Delete `node_modules` folder and reinstall:
     ```bash
     rmdir /s /q node_modules
     npm install
     ```

## Usage

### Terminal Controls

- **Type anywhere** - Just hover over the white page and start typing
- **Tab** - Autocomplete first suggestion
- **Escape** - Hide suggestions
- **Right-click** - Open context menu (Copy/Paste/Select All)
- **Ctrl+Shift+C** - Copy selected text
- **Ctrl+Shift+V** - Paste from clipboard

### File Menu (Click "File" tab)

- **Terminal Actions** - Clear, reset, copy, paste, navigation
- **Windows Tools** - Quick access to ipconfig, netstat, ping, tasklist, etc.
- **View Options** - Change font size and themes
- **Session Management** - Export history and terminal buffer

### Customization

- **Avatar** - Click the blue circle (top-right) to set your initials
- **Themes** - File → View Options → Choose theme
- **Font Size** - File → View Options → Adjust size

### Windows Tools Launcher

Access common Windows tools instantly from File → Windows Tools:

**Network Tools:**
- IP Configuration (ipconfig)
- Network Statistics (netstat)
- Ping connectivity test

**System Tools:**
- Task List (running processes)
- System Info (detailed system information)
- PowerShell (launch PowerShell)

## Building for Distribution

To package the app as a standalone executable:

1. **Install electron-builder**
   ```bash
   npm install electron-builder --save-dev
   ```

2. **Add to package.json**
   ```json
   "build": {
     "appId": "com.wordterm.cmd",
     "productName": "WordTerm CMD",
     "win": {
       "target": "nsis",
       "icon": "icon.png"
     }
   }
   ```

3. **Build**
   ```bash
   npx electron-builder --win
   ```

The installer will be created in the `dist` folder.

## Privacy & Security

- **No Telemetry** - Zero tracking or data collection
- **No Internet Required** - Works completely offline
- **Local Only** - All data stays on your machine
- **No Account Needed** - No registration or login

## Technical Stack

- **Electron** v28.0.0 - Desktop application framework
- **xterm.js** v5.3.0 - Terminal emulator
- **node-pty** v1.0.0 - Pseudo-terminal support
- **Native Windows CMD** - Real Windows Command Prompt

## License

MIT License - Feel free to use, modify, and distribute.

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

## Disclaimer

This tool is for **educational and privacy purposes only**. Use responsibly and in accordance with your organization's policies.

## Support

If you encounter issues:
1. Check the Troubleshooting section above
2. Review closed issues on GitHub
3. Open a new issue with details

---

**Note:** This is a terminal emulator for legitimate privacy and productivity use. Always follow applicable laws and regulations.
