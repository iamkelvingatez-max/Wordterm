const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('wordterm', {
  ptyCreate: (opts) => ipcRenderer.invoke('pty:create', opts),
  ptyWrite: (id, data) => ipcRenderer.send('pty:write', { id, data }),
  ptyResize: (id, cols, rows) => ipcRenderer.send('pty:resize', { id, cols, rows }),
  ptyKill: (id) => ipcRenderer.send('pty:kill', { id }),

  onPtyData: (fn) => ipcRenderer.on('pty:data', (_e, payload) => fn(payload)),
  onPtyExit: (fn) => ipcRenderer.on('pty:exit', (_e, payload) => fn(payload)),

  clipRead: () => ipcRenderer.invoke('clip:read'),
  clipWrite: (text) => ipcRenderer.invoke('clip:write', text),
  clipReadSelection: () => ipcRenderer.invoke('clip:readSelection'),
  clipWriteSelection: (text) => ipcRenderer.invoke('clip:writeSelection', text)
});
