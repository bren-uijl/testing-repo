const { app, BrowserWindow, session, ipcMain, dialog, nativeTheme, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const Store = require('electron-store');

const ExtensionManager = require('./extensions/extension-manager');
const ChromeWebStoreBridge = require('./extensions/chrome-webstore-bridge');
const PermissionManager = require('./extensions/permission-manager');
const PrivacyShield = require('./features/privacy-shield');
const DownloadManager = require('./features/download-manager');
const ReadingMode = require('./features/reading-mode');
const PasswordManager = require('./features/password-manager');

const store = new Store();

let mainWindow;
let extensionManager;
let chromeWebStoreBridge;
let permissionManager;
let privacyShield;
let downloadManager;
let readingMode;
let passwordManager;

function createMainWindow() {
  const windowState = store.get('windowState', {
    width: 1280,
    height: 800,
    x: undefined,
    y: undefined,
  });

  mainWindow = new BrowserWindow({
    width: windowState.width,
    height: windowState.height,
    x: windowState.x,
    y: windowState.y,
    minWidth: 800,
    minHeight: 600,
    frame: false,
    backgroundColor: nativeTheme.shouldUseDarkColors ? '#1a1a2e' : '#ffffff',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webviewTag: true,
      plugins: true,
      experimentalFeatures: true,
      preload: path.join(__dirname, 'preload.js'),
    },
    show: false,
  });

  mainWindow.loadFile(path.join(__dirname, 'ui', 'browser.html'));

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  mainWindow.on('close', () => {
    const bounds = mainWindow.getBounds();
    store.set('windowState', bounds);
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  setupFeatures();
  setupIpcHandlers(mainWindow);

  return mainWindow;
}

function setupFeatures() {
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
  chromeWebStoreBridge = new ChromeWebStoreBridge(extensionManager);
  permissionManager = new PermissionManager();

  session.defaultSession.on('will-download', (event, item, webContents) => {
    downloadManager.registerDownload(webContents, item);
  });

  applyPrivacyShield();
  loadInstalledExtensions();
}

function applyPrivacyShield() {
  const blockedDomains = privacyShield.getBlockedDomains();

  session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
    if (!privacyShield.isEnabled()) {
      callback({});
      return;
    }

    const url = new URL(details.url);
    if (blockedDomains.some(domain => url.hostname.includes(domain))) {
      privacyShield.incrementBlockCount();
      callback({ cancel: true });
    } else {
      callback({});
    }
  });
}

async function loadInstalledExtensions() {
  const extensions = extensionManager.getExtensions();

  for (const ext of extensions) {
    if (ext.enabled) {
      try {
        await session.defaultSession.loadExtension(ext.path);
      } catch (error) {
        console.error(`Failed to load extension ${ext.name}:`, error);
      }
    }
  }
}

function setupIpcHandlers(window) {
  ipcMain.handle('get-user-data-path', () => app.getPath('userData'));
  ipcMain.handle('get-app-version', () => app.getVersion());
  ipcMain.handle('open-dialog', async (_, options) => {
    return dialog.showOpenDialog(window, options);
  });

  ipcMain.on('new-window', () => {
    window.webContents.send('new-tab');
  });

  ipcMain.on('navigate', (_, url) => {
    window.webContents.send('navigate-to', url);
  });

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

  ipcMain.handle('install-extension', async (_, extPath) => {
    try {
      const manifestPath = path.join(extPath, 'manifest.json');
      const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
      const analyzed = permissionManager.analyze(manifest.permissions || []);

      if (analyzed.riskLevel === 'high') {
        const result = await dialog.showMessageBox(window, {
          type: 'warning',
          title: 'Extension Permissions',
          message: 'This extension requests high-risk permissions',
          detail: analyzed.summary,
          buttons: ['Cancel', 'Install Anyway'],
          cancelId: 0,
        });

        if (result.response !== 1) {
          return { success: false, error: 'User cancelled' };
        }
      }

      const result = await extensionManager.loadUnpackedExtension(extPath);
      return { success: !!result, result };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  ipcMain.handle('get-extensions', async () => {
    return extensionManager.getExtensions();
  });

  ipcMain.handle('remove-extension', async (_, extId) => {
    try {
      await extensionManager.uninstallExtension(extId);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  ipcMain.handle('toggle-extension', (_, extId, enabled) => {
    return extensionManager.toggleExtension(extId, enabled);
  });

  ipcMain.handle('load-unpacked-extension', async () => {
    const result = await dialog.showOpenDialog(window, {
      properties: ['openDirectory'],
      title: 'Select Extension Folder',
    });
    if (!result.canceled && result.filePaths.length > 0) {
      return extensionManager.loadUnpackedExtension(result.filePaths[0]);
    }
    return null;
  });

  ipcMain.handle('analyze-permissions', (_, manifest) => {
    return extensionManager.analyzePermissions(manifest);
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

  ipcMain.handle('reading-mode-activate', async () => {
    const webContents = mainWindow.webContents;
    return readingMode.activate(webContents);
  });

  ipcMain.handle('reading-mode-deactivate', async () => {
    const webContents = mainWindow.webContents;
    return readingMode.deactivate(webContents);
  });

  ipcMain.handle('extract-article', async (_, html) => {
    return readingMode.extractArticle(html);
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
    const result = await dialog.showSaveDialog(window, {
      title: 'Export Passwords',
      defaultPath: 'nexus-passwords.csv',
      filters: [{ name: 'CSV', extensions: ['csv'] }],
    });
    if (!result.canceled && result.filePath) {
      return passwordManager.exportToCSV(result.filePath, masterPassword);
    }
    return false;
  });

  ipcMain.handle('import-passwords', async (_, filePath, masterPassword) => {
    return passwordManager.importFromCSV(filePath, masterPassword);
  });

  ipcMain.handle('open-settings', () => {
    const settingsWindow = new BrowserWindow({
      width: 900,
      height: 700,
      title: 'Nexus Settings',
      parent: mainWindow,
      modal: false,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: path.join(__dirname, 'preload.js'),
      },
    });

    settingsWindow.loadFile(path.join(__dirname, 'ui', 'settings.html'));
  });

  ipcMain.handle('open-external', async (_, url) => {
    await shell.openExternal(url);
    return true;
  });

  ipcMain.handle('get-settings', () => {
    return {
      privacy: privacyShield.getSettings(),
      downloads: downloadManager.getSettings(),
      reading: readingMode.getSettings(),
    };
  });

  ipcMain.handle('save-settings', (_, settings) => {
    privacyShield.saveSettings(settings.privacy || {});
    downloadManager.saveSettings(settings.downloads || {});
    readingMode.saveSettings(settings.reading || {});
    return true;
  });
}

app.whenReady().then(() => {
  createMainWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.commandLine.appendSwitch('enable-extensions');
app.commandLine.appendSwitch('enable-features', 'WebComponentsV0Enabled');
app.commandLine.appendSwitch('disable-site-isolation-trials');
app.commandLine.appendSwitch('force-webrtc-ip-handling-policy', 'disable_non_proxied_udp');
app.commandLine.appendSwitch('webrtc-ip-handling-policy', 'disable_non_proxied_udp');
