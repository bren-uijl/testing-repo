const { app, BrowserWindow, session, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');

// Import features
const PrivacyShield = require('./features/privacy-shield');
const DownloadManager = require('./features/download-manager');
const ReadingMode = require('./features/reading-mode');
const PasswordManager = require('./features/password-manager');
const ExtensionManager = require('./extensions/extension-manager');

let mainWindow;
let privacyShield;
let downloadManager;
let readingMode;
let passwordManager;
let extensionManager;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    frame: false,
    backgroundColor: '#1a1a2e',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
      webviewTag: true
    }
  });

  mainWindow.loadFile(path.join(__dirname, 'ui', 'browser.html'));

  mainWindow.webContents.on('did-finish-load', () => {
    initializeFeatures();
  });
}

function initializeFeatures() {
  const userDataPath = app.getPath('userData');
  const extensionsPath = path.join(userDataPath, 'extensions');
  const downloadsPath = path.join(userDataPath, 'downloads');

  if (!fs.existsSync(extensionsPath)) {
    fs.mkdirSync(extensionsPath, { recursive: true });
  }
  if (!fs.existsSync(downloadsPath)) {
    fs.mkdirSync(downloadsPath, { recursive: true });
  }

  privacyShield = new PrivacyShield();
  downloadManager = new DownloadManager(mainWindow, downloadsPath);
  readingMode = new ReadingMode(mainWindow);
  passwordManager = new PasswordManager(userDataPath);
  extensionManager = new ExtensionManager(session.defaultSession, extensionsPath);

  setupIPC();
  applyPrivacyShield();
}

function applyPrivacyShield() {
  const blockedDomains = privacyShield.getBlockedDomains();

  session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
    const url = new URL(details.url);
    if (blockedDomains.some(domain => url.hostname.includes(domain))) {
      privacyShield.incrementBlockCount();
      callback({ cancel: true });
    } else {
      callback({});
    }
  });

  session.defaultSession.webRequest.onBeforeSendHeaders((details, callback) => {
    const headers = { ...details.requestHeaders };
    const trackingHeaders = ['X-Do-Not-Track', 'DNT', 'Sec-GPC'];
    trackingHeaders.forEach(header => {
      if (headers[header]) {
        delete headers[header];
      }
    });
    callback({ requestHeaders: headers });
  });
}

function setupIPC() {
  ipcMain.handle('window-minimize', () => {
    mainWindow.minimize();
  });

  ipcMain.handle('window-maximize', () => {
    if (mainWindow.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow.maximize();
    }
  });

  ipcMain.handle('window-close', () => {
    mainWindow.close();
  });

  ipcMain.handle('get-privacy-stats', () => {
    return privacyShield.getStats();
  });

  ipcMain.handle('toggle-privacy', (_, enabled) => {
    privacyShield.setEnabled(enabled);
    if (enabled) {
      applyPrivacyShield();
    }
    return privacyShield.isEnabled();
  });

  ipcMain.handle('get-blocked-domains', () => {
    return privacyShield.getBlockedDomains();
  });

  ipcMain.handle('add-blocked-domain', (_, domain) => {
    privacyShield.addBlockedDomain(domain);
    return privacyShield.getBlockedDomains();
  });

  ipcMain.handle('remove-blocked-domain', (_, domain) => {
    privacyShield.removeBlockedDomain(domain);
    return privacyShield.getBlockedDomains();
  });

  ipcMain.handle('get-downloads', () => {
    return downloadManager.getDownloads();
  });

  ipcMain.handle('pause-download', (_, downloadId) => {
    return downloadManager.pauseDownload(downloadId);
  });

  ipcMain.handle('resume-download', (_, downloadId) => {
    return downloadManager.resumeDownload(downloadId);
  });

  ipcMain.handle('cancel-download', (_, downloadId) => {
    return downloadManager.cancelDownload(downloadId);
  });

  ipcMain.handle('open-download', (_, downloadId) => {
    return downloadManager.openDownload(downloadId);
  });

  ipcMain.handle('clear-downloads', () => {
    return downloadManager.clearDownloads();
  });

  ipcMain.handle('extract-article', async (_, html) => {
    return readingMode.extractArticle(html);
  });

  ipcMain.handle('save-password', async (_, site, username, password) => {
    return passwordManager.savePassword(site, username, password);
  });

  ipcMain.handle('get-passwords', async () => {
    return passwordManager.getPasswords();
  });

  ipcMain.handle('delete-password', async (_, id) => {
    return passwordManager.deletePassword(id);
  });

  ipcMain.handle('export-passwords', async (_, masterPassword) => {
    const result = await dialog.showSaveDialog(mainWindow, {
      title: 'Export Passwords',
      defaultPath: 'nexus-passwords.csv',
      filters: [{ name: 'CSV', extensions: ['csv'] }]
    });
    if (!result.canceled && result.filePath) {
      return passwordManager.exportToCSV(result.filePath, masterPassword);
    }
    return false;
  });

  ipcMain.handle('import-passwords', async (_, filePath, masterPassword) => {
    return passwordManager.importFromCSV(filePath, masterPassword);
  });

  ipcMain.handle('install-extension', async (_, extensionId) => {
    return extensionManager.installFromWebStore(extensionId);
  });

  ipcMain.handle('load-unpacked-extension', async () => {
    const result = await dialog.showOpenDialog(mainWindow, {
      properties: ['openDirectory']
    });
    if (!result.canceled && result.filePaths.length > 0) {
      return extensionManager.loadUnpackedExtension(result.filePaths[0]);
    }
    return null;
  });

  ipcMain.handle('get-extensions', () => {
    return extensionManager.getExtensions();
  });

  ipcMain.handle('toggle-extension', (_, extensionId, enabled) => {
    return extensionManager.toggleExtension(extensionId, enabled);
  });

  ipcMain.handle('uninstall-extension', (_, extensionId) => {
    return extensionManager.uninstallExtension(extensionId);
  });

  ipcMain.handle('analyze-permissions', (_, manifest) => {
    return extensionManager.analyzePermissions(manifest);
  });

  ipcMain.handle('get-settings', () => {
    return {
      privacy: privacyShield.getSettings(),
      downloads: downloadManager.getSettings(),
      reading: readingMode.getSettings()
    };
  });

  ipcMain.handle('save-settings', (_, settings) => {
    privacyShield.saveSettings(settings.privacy || {});
    downloadManager.saveSettings(settings.downloads || {});
    readingMode.saveSettings(settings.reading || {});
    return true;
  });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});
