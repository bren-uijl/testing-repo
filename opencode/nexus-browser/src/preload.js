const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  windowControls: {
    minimize: () => ipcRenderer.invoke('window-minimize'),
    maximize: () => ipcRenderer.invoke('window-maximize'),
    close: () => ipcRenderer.invoke('window-close')
  },
  privacy: {
    getStats: () => ipcRenderer.invoke('get-privacy-stats'),
    toggle: (enabled) => ipcRenderer.invoke('toggle-privacy', enabled),
    getBlockedDomains: () => ipcRenderer.invoke('get-blocked-domains'),
    addBlockedDomain: (domain) => ipcRenderer.invoke('add-blocked-domain', domain),
    removeBlockedDomain: (domain) => ipcRenderer.invoke('remove-blocked-domain', domain)
  },
  downloads: {
    getDownloads: () => ipcRenderer.invoke('get-downloads'),
    pauseDownload: (id) => ipcRenderer.invoke('pause-download', id),
    resumeDownload: (id) => ipcRenderer.invoke('resume-download', id),
    cancelDownload: (id) => ipcRenderer.invoke('cancel-download', id),
    openDownload: (id) => ipcRenderer.invoke('open-download', id),
    clearDownloads: () => ipcRenderer.invoke('clear-downloads')
  },
  readingMode: {
    extractArticle: (html) => ipcRenderer.invoke('extract-article', html)
  },
  passwords: {
    savePassword: (site, username, password) => ipcRenderer.invoke('save-password', site, username, password),
    getPasswords: () => ipcRenderer.invoke('get-passwords'),
    deletePassword: (id) => ipcRenderer.invoke('delete-password', id),
    exportPasswords: (masterPassword) => ipcRenderer.invoke('export-passwords', masterPassword),
    importPasswords: (filePath, masterPassword) => ipcRenderer.invoke('import-passwords', filePath, masterPassword)
  },
  extensions: {
    installFromWebStore: (extensionId) => ipcRenderer.invoke('install-extension', extensionId),
    loadUnpacked: () => ipcRenderer.invoke('load-unpacked-extension'),
    getExtensions: () => ipcRenderer.invoke('get-extensions'),
    toggleExtension: (id, enabled) => ipcRenderer.invoke('toggle-extension', id, enabled),
    uninstallExtension: (id) => ipcRenderer.invoke('uninstall-extension', id),
    analyzePermissions: (manifest) => ipcRenderer.invoke('analyze-permissions', manifest)
  },
  settings: {
    getSettings: () => ipcRenderer.invoke('get-settings'),
    saveSettings: (settings) => ipcRenderer.invoke('save-settings', settings)
  }
});
