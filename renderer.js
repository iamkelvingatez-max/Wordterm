const { ipcRenderer } = require('electron');
const { Terminal } = require('xterm');
const { FitAddon } = require('xterm-addon-fit');
const fs = require('fs');
const os = require('os');
const { execSync } = require('child_process');
const path = require('path');

function $(sel){ return document.querySelector(sel); }

function makeMenu(){
  const m = document.createElement('div');
  m.id = 'term-menu';
  m.style.position = 'fixed';
  m.style.zIndex = '999999';
  m.style.minWidth = '180px';
  m.style.background = '#ffffff';
  m.style.border = '1px solid rgba(0,0,0,.18)';
  m.style.boxShadow = '0 10px 24px rgba(0,0,0,.18)';
  m.style.borderRadius = '6px';
  m.style.padding = '6px';
  m.style.display = 'none';
  m.style.fontFamily = '"Segoe UI Variable","Segoe UI",system-ui,-apple-system,Arial,sans-serif';
  m.style.fontSize = '13px';
  m.style.userSelect = 'none';

  const item = (label, onClick) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.textContent = label;
    b.style.width = '100%';
    b.style.textAlign = 'left';
    b.style.padding = '8px 10px';
    b.style.border = 'none';
    b.style.background = 'transparent';
    b.style.borderRadius = '4px';
    b.style.cursor = 'pointer';
    b.onmouseenter = () => { b.style.background = 'rgba(0,0,0,.06)'; };
    b.onmouseleave = () => { b.style.background = 'transparent'; };
    b.onclick = () => { hide(); onClick(); };
    return b;
  };

  const sep = () => {
    const s = document.createElement('div');
    s.style.height = '1px';
    s.style.margin = '6px 4px';
    s.style.background = 'rgba(0,0,0,.12)';
    return s;
  };

  m.appendChild(item('Copy', () => window.__wordtermCopy?.()));
  m.appendChild(item('Paste', () => window.__wordtermPaste?.()));
  m.appendChild(item('Cut', () => window.__wordtermCut?.()));
  m.appendChild(sep());
  m.appendChild(item('Select All', () => window.__wordtermSelectAll?.()));

  document.body.appendChild(m);

  function hide(){ m.style.display = 'none'; }
  function show(x,y){
    m.style.display = 'block';
    const r = m.getBoundingClientRect();
    const maxX = window.innerWidth - r.width - 8;
    const maxY = window.innerHeight - r.height - 8;
    m.style.left = Math.max(8, Math.min(x, maxX)) + 'px';
    m.style.top  = Math.max(8, Math.min(y, maxY)) + 'px';
  }

  window.addEventListener('mousedown', (e) => {
    if (m.style.display === 'none') return;
    if (!m.contains(e.target)) hide();
  }, true);

  window.addEventListener('blur', hide);
  return { show, hide };
}

function makeAvatarEditor() {
  const overlay = document.createElement('div');
  overlay.style.position = 'fixed';
  overlay.style.top = '0';
  overlay.style.left = '0';
  overlay.style.right = '0';
  overlay.style.bottom = '0';
  overlay.style.background = 'rgba(0,0,0,.5)';
  overlay.style.zIndex = '999999';
  overlay.style.display = 'none';
  overlay.style.alignItems = 'center';
  overlay.style.justifyContent = 'center';

  const dialog = document.createElement('div');
  dialog.style.background = '#ffffff';
  dialog.style.borderRadius = '8px';
  dialog.style.boxShadow = '0 16px 48px rgba(0,0,0,.25)';
  dialog.style.padding = '24px';
  dialog.style.width = '320px';
  dialog.style.fontFamily = '"Segoe UI Variable","Segoe UI",system-ui,-apple-system,Arial,sans-serif';

  const title = document.createElement('h3');
  title.textContent = 'Customize Avatar';
  title.style.margin = '0 0 20px 0';
  title.style.fontSize = '18px';
  title.style.fontWeight = '600';
  title.style.color = '#1f1f1f';

  const label = document.createElement('label');
  label.textContent = 'Initials (1-3 characters)';
  label.style.display = 'block';
  label.style.fontSize = '13px';
  label.style.color = '#5f5f5f';
  label.style.marginBottom = '8px';

  const input = document.createElement('input');
  input.type = 'text';
  input.maxLength = 3;
  input.style.width = '100%';
  input.style.padding = '10px 12px';
  input.style.border = '1px solid rgba(0,0,0,.15)';
  input.style.borderRadius = '6px';
  input.style.fontSize = '14px';
  input.style.fontFamily = 'inherit';
  input.style.outline = 'none';
  input.style.textTransform = 'uppercase';

  input.addEventListener('focus', () => {
    input.style.borderColor = '#0078d4';
    input.style.boxShadow = '0 0 0 3px rgba(0,120,212,.1)';
  });

  input.addEventListener('blur', () => {
    input.style.borderColor = 'rgba(0,0,0,.15)';
    input.style.boxShadow = 'none';
  });

  const buttons = document.createElement('div');
  buttons.style.display = 'flex';
  buttons.style.gap = '10px';
  buttons.style.marginTop = '20px';

  const cancelBtn = document.createElement('button');
  cancelBtn.textContent = 'Cancel';
  cancelBtn.style.flex = '1';
  cancelBtn.style.padding = '10px';
  cancelBtn.style.border = '1px solid rgba(0,0,0,.15)';
  cancelBtn.style.borderRadius = '6px';
  cancelBtn.style.background = '#ffffff';
  cancelBtn.style.fontSize = '14px';
  cancelBtn.style.fontWeight = '600';
  cancelBtn.style.cursor = 'pointer';
  cancelBtn.style.transition = 'all 0.15s ease';
  cancelBtn.style.fontFamily = 'inherit';

  cancelBtn.onmouseenter = () => {
    cancelBtn.style.background = '#f5f5f5';
  };
  cancelBtn.onmouseleave = () => {
    cancelBtn.style.background = '#ffffff';
  };

  const saveBtn = document.createElement('button');
  saveBtn.textContent = 'Save';
  saveBtn.style.flex = '1';
  saveBtn.style.padding = '10px';
  saveBtn.style.border = 'none';
  saveBtn.style.borderRadius = '6px';
  saveBtn.style.background = 'linear-gradient(135deg, #0078d4 0%, #0066b8 100%)';
  saveBtn.style.color = '#ffffff';
  saveBtn.style.fontSize = '14px';
  saveBtn.style.fontWeight = '600';
  saveBtn.style.cursor = 'pointer';
  saveBtn.style.transition = 'all 0.15s ease';
  saveBtn.style.fontFamily = 'inherit';
  saveBtn.style.boxShadow = '0 2px 4px rgba(0,120,212,.3)';

  saveBtn.onmouseenter = () => {
    saveBtn.style.background = 'linear-gradient(135deg, #006cbe 0%, #005ba1 100%)';
    saveBtn.style.transform = 'translateY(-1px)';
    saveBtn.style.boxShadow = '0 3px 6px rgba(0,120,212,.35)';
  };
  saveBtn.onmouseleave = () => {
    saveBtn.style.background = 'linear-gradient(135deg, #0078d4 0%, #0066b8 100%)';
    saveBtn.style.transform = 'translateY(0)';
    saveBtn.style.boxShadow = '0 2px 4px rgba(0,120,212,.3)';
  };

  buttons.appendChild(cancelBtn);
  buttons.appendChild(saveBtn);

  dialog.appendChild(title);
  dialog.appendChild(label);
  dialog.appendChild(input);
  dialog.appendChild(buttons);
  overlay.appendChild(dialog);
  document.body.appendChild(overlay);

  function show(currentInitials, onSave) {
    input.value = currentInitials;
    overlay.style.display = 'flex';
    setTimeout(() => input.focus(), 50);

    cancelBtn.onclick = () => {
      overlay.style.display = 'none';
    };

    saveBtn.onclick = () => {
      const newInitials = input.value.trim().toUpperCase();
      if (newInitials.length > 0) {
        onSave(newInitials);
        overlay.style.display = 'none';
      }
    };

    input.onkeydown = (e) => {
      if (e.key === 'Enter') {
        saveBtn.click();
      } else if (e.key === 'Escape') {
        cancelBtn.click();
      }
    };
  }

  overlay.onclick = (e) => {
    if (e.target === overlay) {
      overlay.style.display = 'none';
    }
  };

  return { show };
}

function makeDropdown(triggerEl, items, currentValue, onSelect) {
  const dropdown = document.createElement('div');
  dropdown.style.position = 'fixed';
  dropdown.style.zIndex = '999999';
  dropdown.style.minWidth = triggerEl.offsetWidth + 'px';
  dropdown.style.maxHeight = '300px';
  dropdown.style.background = '#ffffff';
  dropdown.style.border = '1px solid rgba(0,0,0,.15)';
  dropdown.style.borderRadius = '6px';
  dropdown.style.boxShadow = '0 4px 16px rgba(0,0,0,.15)';
  dropdown.style.display = 'none';
  dropdown.style.overflowY = 'auto';
  dropdown.style.padding = '4px';

  items.forEach(item => {
    const div = document.createElement('div');
    div.textContent = item.label;
    div.style.padding = '8px 12px';
    div.style.cursor = 'pointer';
    div.style.borderRadius = '4px';
    div.style.fontSize = '13px';
    div.style.transition = 'all 0.15s ease';
    
    if (item.value === currentValue) {
      div.style.background = 'rgba(0,120,212,.1)';
      div.style.fontWeight = '600';
    }

    div.onmouseenter = () => {
      div.style.background = 'rgba(0,0,0,.06)';
    };
    div.onmouseleave = () => {
      if (item.value !== currentValue) {
        div.style.background = 'transparent';
      } else {
        div.style.background = 'rgba(0,120,212,.1)';
      }
    };

    div.onclick = () => {
      onSelect(item.value, item.label);
      hide();
    };

    dropdown.appendChild(div);
  });

  document.body.appendChild(dropdown);

  function hide() {
    dropdown.style.display = 'none';
  }

  function show() {
    const rect = triggerEl.getBoundingClientRect();
    dropdown.style.left = rect.left + 'px';
    dropdown.style.top = (rect.bottom + 2) + 'px';
    dropdown.style.display = 'block';
  }

  function toggle() {
    if (dropdown.style.display === 'none') {
      show();
    } else {
      hide();
    }
  }

  triggerEl.addEventListener('click', (e) => {
    e.stopPropagation();
    toggle();
  });

  document.addEventListener('click', (e) => {
    if (!dropdown.contains(e.target) && e.target !== triggerEl) {
      hide();
    }
  });

  return { hide, show, toggle };
}

function makeAutocomplete(term, ptyId, cwdRef){
  const container = document.createElement('div');
  container.id = 'autocomplete';
  container.style.position = 'fixed';
  container.style.zIndex = '999998';
  container.style.display = 'none';
  container.style.gap = '8px';
  container.style.flexDirection = 'row';
  document.body.appendChild(container);

  let suggestions = [];
  let currentInput = '';
  let history = [];

  const hide = () => {
    container.style.display = 'none';
    suggestions = [];
  };

  const show = (x, y, items) => {
    if (!items || items.length === 0) {
      hide();
      return;
    }
    
    suggestions = items.slice(0, 3);
    
    container.innerHTML = '';
    container.style.display = 'flex';
    
    suggestions.forEach((item, i) => {
      const btn = document.createElement('button');
      btn.textContent = item.text;
      btn.type = 'button';
      
      btn.style.padding = '6px 14px';
      btn.style.background = '#ffffff';
      btn.style.border = '1px solid rgba(0,0,0,.15)';
      btn.style.borderRadius = '16px';
      btn.style.fontFamily = '"Segoe UI Variable","Segoe UI",system-ui,-apple-system,Arial,sans-serif';
      btn.style.fontSize = '13px';
      btn.style.color = '#1f1f1f';
      btn.style.cursor = 'pointer';
      btn.style.boxShadow = '0 2px 6px rgba(0,0,0,.1)';
      btn.style.transition = 'all 0.1s ease';
      btn.style.whiteSpace = 'nowrap';
      
      btn.onmouseenter = () => {
        btn.style.background = '#f5f5f5';
        btn.style.transform = 'translateY(-1px)';
        btn.style.boxShadow = '0 3px 8px rgba(0,0,0,.15)';
      };
      
      btn.onmouseleave = () => {
        btn.style.background = '#ffffff';
        btn.style.transform = 'translateY(0)';
        btn.style.boxShadow = '0 2px 6px rgba(0,0,0,.1)';
      };
      
      btn.onclick = () => {
        insertSuggestion(item);
        hide();
      };
      
      container.appendChild(btn);
    });
    
    container.style.left = x + 'px';
    container.style.top = (y - 50) + 'px';
  };

  const insertSuggestion = (suggestion) => {
    if (!suggestion) return;
    
    const text = suggestion.text;
    const toDelete = currentInput.length;
    
    for (let i = 0; i < toDelete; i++) {
      ipcRenderer.send('pty:write', { id: ptyId, data: '\x7f' });
    }
    
    ipcRenderer.send('pty:write', { id: ptyId, data: text });
    
    currentInput = '';
    hide();
  };

  const getCommands = (prefix) => {
    try {
      const paths = (process.env.PATH || '').split(':');
      const commands = new Set();
      
      paths.forEach(p => {
        try {
          const files = fs.readdirSync(p);
          files.forEach(f => {
            if (f.startsWith(prefix)) {
              try {
                const stat = fs.statSync(`${p}/${f}`);
                if (stat.mode & 0o111) {
                  commands.add(f);
                }
              } catch {}
            }
          });
        } catch {}
      });
      
      return Array.from(commands).slice(0, 10).map(c => ({
        text: c,
        type: 'command'
      }));
    } catch {
      return [];
    }
  };

  const getFiles = (prefix) => {
    try {
      const files = fs.readdirSync(cwdRef.current);
      return files
        .filter(f => f.startsWith(prefix) && !f.startsWith('.'))
        .slice(0, 10)
        .map(f => ({
          text: f,
          type: 'file'
        }));
    } catch {
      return [];
    }
  };

  const getHistory = (prefix) => {
    return history
      .filter(h => h.startsWith(prefix))
      .reverse()
      .slice(0, 5)
      .map(h => ({
        text: h,
        type: 'history'
      }));
  };

  const getSuggestions = (input) => {
    if (!input || input.length < 1) return [];
    
    const parts = input.split(/\s+/);
    const lastPart = parts[parts.length - 1];
    
    let results = [];
    
    if (parts.length === 1) {
      results = [
        ...getHistory(input),
        ...getCommands(input)
      ];
    } else {
      results = getFiles(lastPart);
    }
    
    return results.slice(0, 3);
  };

  const addHistory = (cmd) => {
    if (cmd.trim()) {
      history.push(cmd.trim());
      if (history.length > 100) history.shift();
    }
  };

  const clearHistory = () => {
    history = [];
  };

  const exportHistory = () => {
    return history;
  };

  return { 
    hide, 
    show: (x, y, input) => {
      currentInput = input;
      const suggestions = getSuggestions(input);
      show(x, y, suggestions);
    },
    insertFirst: () => { if (suggestions.length > 0) insertSuggestion(suggestions[0]); }, 
    isVisible: () => container.style.display !== 'none',
    addHistory,
    clearHistory,
    exportHistory
  };
}

(async function boot(){
  const termHost = $('#terminal');
  if (!termHost) {
    console.error('Missing #terminal');
    return;
  }

  termHost.style.userSelect = 'text';
  termHost.style.cursor = 'text';

  const fitAddon = new FitAddon();
  
  let currentFont = 'DejaVu Sans Mono';
  let currentSize = 14;
  let userInitials = localStorage.getItem('wordterm-initials') || 'KG';

  const term = new Terminal({
    cursorBlink: true,
    cursorStyle: 'bar',
    cursorWidth: 2,
    scrollback: 8000,
    convertEol: true,
    fontFamily: currentFont,
    fontSize: currentSize,
    theme: { 
      background: '#ffffff', 
      foreground: '#111111',
      cursor: '#000000',
      cursorAccent: '#ffffff',
      selection: '#0078d4',
      selectionBackground: '#0078d4',
      selectionForeground: '#ffffff'
    },
    allowTransparency: false
  });

  term.open(termHost);
  term.loadAddon(fitAddon);
  fitAddon.fit();

  // Avatar editor
  const avatarEl = document.querySelector('.avatar');
  if (avatarEl) {
    avatarEl.textContent = userInitials;
    avatarEl.style.cursor = 'pointer';
    
    const avatarEditor = makeAvatarEditor();
    
    avatarEl.onclick = () => {
      avatarEditor.show(userInitials, (newInitials) => {
        userInitials = newInitials;
        avatarEl.textContent = newInitials;
        localStorage.setItem('wordterm-initials', newInitials);
      });
    };
  }

  // Font dropdowns
  const fontNameEl = document.querySelector('.drop:not(.small)');
  const fontSizeEl = document.querySelector('.drop.small');

  // Font size buttons (+/-)
  const fontButtons = document.querySelectorAll('.row .btn');
  let increaseFontBtn = null;
  let decreaseFontBtn = null;

  fontButtons.forEach((btn, idx) => {
    const title = btn.getAttribute('title');
    if (title === 'Increase Font Size') {
      increaseFontBtn = btn;
    } else if (title === 'Decrease Font Size') {
      decreaseFontBtn = btn;
    }
  });

  if (increaseFontBtn) {
    increaseFontBtn.onclick = () => {
      currentSize = Math.min(28, currentSize + 1);
      term.options.fontSize = currentSize;
      if (fontSizeEl) {
        fontSizeEl.querySelector('span:first-child').textContent = currentSize;
      }
      term.refresh(0, term.rows - 1);
      fitAddon.fit();
    };
  }

  if (decreaseFontBtn) {
    decreaseFontBtn.onclick = () => {
      currentSize = Math.max(8, currentSize - 1);
      term.options.fontSize = currentSize;
      if (fontSizeEl) {
        fontSizeEl.querySelector('span:first-child').textContent = currentSize;
      }
      term.refresh(0, term.rows - 1);
      fitAddon.fit();
    };
  }

  if (fontNameEl) {
    const fontNameText = fontNameEl.querySelector('span:first-child');
    fontNameText.textContent = 'DejaVu Sans Mono';
    
    makeDropdown(fontNameEl, [
      { label: 'DejaVu Sans Mono', value: 'DejaVu Sans Mono' },
      { label: 'Courier New', value: 'Courier New' },
      { label: 'Consolas', value: 'Consolas' },
      { label: 'Monaco', value: 'Monaco' },
      { label: 'Menlo', value: 'Menlo' }
    ], currentFont, (value, label) => {
      currentFont = value;
      term.options.fontFamily = value;
      fontNameText.textContent = label;
      
      term.refresh(0, term.rows - 1);
      fitAddon.fit();
      
      ipcRenderer.send('pty:write', { id, data: '\x0c' });
    });
  }

  if (fontSizeEl) {
    const fontSizeText = fontSizeEl.querySelector('span:first-child');
    fontSizeText.textContent = '14';
    
    makeDropdown(fontSizeEl, [
      { label: '8', value: 8 },
      { label: '9', value: 9 },
      { label: '10', value: 10 },
      { label: '11', value: 11 },
      { label: '12', value: 12 },
      { label: '14', value: 14 },
      { label: '16', value: 16 },
      { label: '18', value: 18 },
      { label: '20', value: 20 },
      { label: '24', value: 24 }
    ], currentSize, (value, label) => {
      currentSize = value;
      term.options.fontSize = value;
      fontSizeText.textContent = label;
      
      term.refresh(0, term.rows - 1);
      fitAddon.fit();
      
      ipcRenderer.send('pty:write', { id, data: '\x0c' });
    });
  }

  const { id, error } = await ipcRenderer.invoke('pty:create', {
    cols: term.cols,
    rows: term.rows,
    shell: '/bin/bash'
  });

  if (!id || error) {
    term.write('\r\n[ERROR] Terminal backend failed.\r\n');
    return;
  }

  const cwdRef = { current: os.homedir() || process.env.HOME || '/' };
  const autocomplete = makeAutocomplete(term, id, cwdRef);

  let lineBuffer = '';

  const isDirectory = (p) => {
    try {
      let fullPath = p;
      if (!path.isAbsolute(p)) {
        fullPath = path.join(cwdRef.current, p);
      }
      const stat = fs.statSync(fullPath);
      return stat.isDirectory();
    } catch {
      return false;
    }
  };

  const sendCommand = (cmd) => {
    ipcRenderer.send('pty:write', { id, data: cmd + '\r' });
  };

  const pasteChunked = (text) => {
    const chunkSize = 200;
    let offset = 0;
    
    const sendChunk = () => {
      if (offset < text.length) {
        const chunk = text.slice(offset, offset + chunkSize);
        ipcRenderer.send('pty:write', { id, data: chunk });
        offset += chunkSize;
        setTimeout(sendChunk, 10);
      }
    };
    
    sendChunk();
  };

  window.__terminalAction = (action) => {
    const closeFileMenu = () => document.getElementById('file-menu').classList.remove('active');
    
    switch(action) {
      case 'clear':
        sendCommand('clear');
        closeFileMenu();
        break;
      case 'reset':
        sendCommand('reset');
        closeFileMenu();
        break;
      case 'copy':
        window.__wordtermCopy?.();
        closeFileMenu();
        break;
      case 'paste':
        window.__wordtermPaste?.();
        closeFileMenu();
        break;
      case 'home':
        sendCommand('cd ~');
        closeFileMenu();
        break;
      case 'root':
        sendCommand('cd /');
        closeFileMenu();
        break;
      case 'back':
        sendCommand('cd -');
        closeFileMenu();
        break;
    }
  };

  window.__launchTool = (tool) => {
    const closeFileMenu = () => document.getElementById('file-menu').classList.remove('active');
    
    const tools = {
      'nmap': 'nmap',
      'masscan': 'masscan',
      'wireshark': 'wireshark',
      'msfconsole': 'msfconsole',
      'sqlmap': 'sqlmap',
      'burpsuite': 'burpsuite',
      'hydra': 'hydra',
      'john': 'john',
      'hashcat': 'hashcat',
      'nikto': 'nikto',
      'gobuster': 'gobuster',
      'ffuf': 'ffuf'
    };
    
    if (tools[tool]) {
      sendCommand(tools[tool]);
      closeFileMenu();
    }
  };

  window.__viewAction = (action) => {
    const closeFileMenu = () => document.getElementById('file-menu').classList.remove('active');
    
    switch(action) {
      case 'font-smaller':
        currentSize = Math.max(8, currentSize - 1);
        term.options.fontSize = currentSize;
        if (fontSizeEl) {
          fontSizeEl.querySelector('span:first-child').textContent = currentSize;
        }
        term.refresh(0, term.rows - 1);
        fitAddon.fit();
        closeFileMenu();
        break;
      case 'font-larger':
        currentSize = Math.min(28, currentSize + 1);
        term.options.fontSize = currentSize;
        if (fontSizeEl) {
          fontSizeEl.querySelector('span:first-child').textContent = currentSize;
        }
        term.refresh(0, term.rows - 1);
        fitAddon.fit();
        closeFileMenu();
        break;
      case 'font-reset':
        currentSize = 14;
        term.options.fontSize = currentSize;
        if (fontSizeEl) {
          fontSizeEl.querySelector('span:first-child').textContent = currentSize;
        }
        term.refresh(0, term.rows - 1);
        fitAddon.fit();
        closeFileMenu();
        break;
      case 'theme-light':
        term.options.theme = {
          background: '#ffffff',
          foreground: '#111111',
          cursor: '#000000',
          cursorAccent: '#ffffff',
          selection: '#0078d4',
          selectionBackground: '#0078d4',
          selectionForeground: '#ffffff'
        };
        closeFileMenu();
        break;
      case 'theme-dark':
        term.options.theme = {
          background: '#1e1e1e',
          foreground: '#d4d4d4',
          cursor: '#ffffff',
          cursorAccent: '#1e1e1e',
          selection: '#264f78',
          selectionBackground: '#264f78',
          selectionForeground: '#ffffff'
        };
        closeFileMenu();
        break;
      case 'theme-matrix':
        term.options.theme = {
          background: '#000000',
          foreground: '#00ff00',
          cursor: '#00ff00',
          cursorAccent: '#000000',
          selection: '#00ff00',
          selectionBackground: '#003300',
          selectionForeground: '#00ff00'
        };
        closeFileMenu();
        break;
      case 'theme-hacker':
        term.options.theme = {
          background: '#0d1117',
          foreground: '#0f0',
          cursor: '#0f0',
          cursorAccent: '#0d1117',
          selection: '#0f0',
          selectionBackground: '#1a3a1a',
          selectionForeground: '#0f0'
        };
        closeFileMenu();
        break;
    }
  };

  window.__sessionAction = (action) => {
    const closeFileMenu = () => document.getElementById('file-menu').classList.remove('active');
    
    switch(action) {
      case 'export-history':
        try {
          const history = autocomplete.exportHistory();
          const content = history.join('\n');
          const blob = new Blob([content], { type: 'text/plain' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = `wordterm-history-${Date.now()}.txt`;
          a.click();
          URL.revokeObjectURL(url);
          term.write('\r\n[History exported]\r\n');
        } catch (e) {
          term.write('\r\n[Export failed]\r\n');
        }
        closeFileMenu();
        break;
      case 'export-buffer':
        try {
          const buffer = term.buffer.active;
          let content = '';
          for (let i = 0; i < buffer.length; i++) {
            const line = buffer.getLine(i);
            if (line) {
              content += line.translateToString(true) + '\n';
            }
          }
          const blob = new Blob([content], { type: 'text/plain' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = `wordterm-buffer-${Date.now()}.txt`;
          a.click();
          URL.revokeObjectURL(url);
          term.write('\r\n[Buffer exported]\r\n');
        } catch (e) {
          term.write('\r\n[Export failed]\r\n');
        }
        closeFileMenu();
        break;
      case 'clear-history':
        autocomplete.clearHistory();
        term.write('\r\n[History cleared]\r\n');
        closeFileMenu();
        break;
      case 'clear-suggestions':
        autocomplete.clearHistory();
        term.write('\r\n[Suggestions cleared]\r\n');
        closeFileMenu();
        break;
    }
  };

  ipcRenderer.on('pty:data', (_e, payload) => {
    if (String(payload.id) !== String(id)) return;
    term.write(payload.data);
    
    if (payload.data.includes('$ ') || payload.data.includes('# ')) {
      try {
        const result = execSync('pwd', { cwd: cwdRef.current }).toString().trim();
        cwdRef.current = result;
      } catch {}
    }
  });

  ipcRenderer.on('pty:exit', (_e, payload) => {
    if (String(payload.id) !== String(id)) return;
    term.write('\r\n[Process exited]\r\n');
  });

  term.onData((data) => {
    if (data === '\r') {
      const trimmed = lineBuffer.trim();
      
      if (trimmed && isDirectory(trimmed)) {
        for (let i = 0; i < lineBuffer.length; i++) {
          ipcRenderer.send('pty:write', { id, data: '\x7f' });
        }
        ipcRenderer.send('pty:write', { id, data: `cd ${trimmed}\r` });
        autocomplete.addHistory(`cd ${trimmed}`);
      } else {
        ipcRenderer.send('pty:write', { id, data: '\r' });
        autocomplete.addHistory(trimmed);
      }
      
      lineBuffer = '';
      autocomplete.hide();
      return;
    }
    
    if (data === '\x7f') {
      lineBuffer = lineBuffer.slice(0, -1);
      ipcRenderer.send('pty:write', { id, data });
      
      if (lineBuffer.length > 0) {
        const rect = term.element.getBoundingClientRect();
        const cursorY = rect.top + (term.buffer.active.cursorY * 17);
        const cursorX = rect.left + (term.buffer.active.cursorX * 9);
        autocomplete.show(cursorX, cursorY, lineBuffer);
      } else {
        autocomplete.hide();
      }
      return;
    }
    
    if (data.length === 1 && data >= ' ') {
      lineBuffer += data;
      ipcRenderer.send('pty:write', { id, data });
      
      const rect = term.element.getBoundingClientRect();
      const cursorY = rect.top + (term.buffer.active.cursorY * 17);
      const cursorX = rect.left + (term.buffer.active.cursorX * 9);
      autocomplete.show(cursorX, cursorY, lineBuffer);
      return;
    }
    
    ipcRenderer.send('pty:write', { id, data });
  });

  const doFit = () => {
    try {
      fitAddon.fit();
      ipcRenderer.send('pty:resize', { id, cols: term.cols, rows: term.rows });
    } catch {}
  };
  window.addEventListener('resize', doFit);

  let isSelecting = false;
  termHost.addEventListener('mousedown', () => { isSelecting = true; });
  termHost.addEventListener('mouseup', () => { 
    isSelecting = false; 
    setTimeout(() => term.focus(), 10);
  });

  term.focus();

  async function doCopy(){
    const sel = term.getSelection();
    if (!sel) return;
    await ipcRenderer.invoke('clip:write', sel);
  }
  
  async function doPaste(){
    const t = await ipcRenderer.invoke('clip:read');
    if (t) {
      if (t.length > 500) {
        pasteChunked(t);
      } else {
        ipcRenderer.send('pty:write', { id, data: t });
      }
    }
  }
  
  async function doCut(){
    await doCopy();
  }
  function doSelectAll(){ term.selectAll(); }

  const menu = makeMenu();
  window.__wordtermCopy = doCopy;
  window.__wordtermPaste = doPaste;
  window.__wordtermCut = doCut;
  window.__wordtermSelectAll = doSelectAll;

  termHost.addEventListener('contextmenu', (e) => {
    e.preventDefault();
    menu.show(e.clientX, e.clientY);
  });

  document.addEventListener('keydown', async (e) => {
    const ctrl = e.ctrlKey || e.metaKey;
    const shift = e.shiftKey;

    if (autocomplete.isVisible() && e.key === 'Tab') {
      e.preventDefault();
      autocomplete.insertFirst();
      return;
    }
    
    if (e.key === 'Escape' && autocomplete.isVisible()) {
      e.preventDefault();
      autocomplete.hide();
      return;
    }

    if (ctrl && shift && (e.key === 'C' || e.key === 'c')) {
      e.preventDefault();
      await doCopy();
      return;
    }
    if (ctrl && shift && (e.key === 'V' || e.key === 'v')) {
      e.preventDefault();
      await doPaste();
      return;
    }
  });

  setTimeout(doFit, 100);
})();
