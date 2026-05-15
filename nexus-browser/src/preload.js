const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('nexusAPI', {
  getUserDataPath: () => ipcRenderer.invoke('get-user-data-path'),
  getAppVersion: () => ipcRenderer.invoke('get-app-version'),
  openDialog: (options) => ipcRenderer.invoke('open-dialog', options),
  newWindow: () => ipcRenderer.send('new-window'),
  navigate: (url) => ipcRenderer.send('navigate', url),
  installExtension: (extPath) => ipcRenderer.invoke('install-extension', extPath),
  getExtensions: () => ipcRenderer.invoke('get-extensions'),
  removeExtension: (extId) => ipcRenderer.invoke('remove-extension', extId),
  onNavigate: (callback) => ipcRenderer.on('navigate-to', (_, url) => callback(url)),
  onNewTab: (callback) => ipcRenderer.on('new-tab', () => callback()),
});
