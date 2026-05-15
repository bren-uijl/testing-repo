const { app, BrowserWindow, session, ipcMain, dialog, nativeTheme, shell } = require('electron');
const path = require('path');
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
    titleBarStyle: 'hiddenInset',
    frame: process.platform === 'darwin',
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
  privacyShield = new PrivacyShield();
  extensionManager = new ExtensionManager();
  chromeWebStoreBridge = new ChromeWebStoreBridge(extensionManager);
  permissionManager = new PermissionManager();
  downloadManager = new DownloadManager();
  readingMode = new ReadingMode();
  passwordManager = new PasswordManager();

  session.defaultSession.on('will-download', (event, item, webContents) => {
    downloadManager.registerDownload(webContents, item);
  });

  loadInstalledExtensions();
}

async function loadInstalledExtensions() {
  const extensions = extensionManager.getInstalledExtensions();

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
    createNewTab();
  });

  ipcMain.on('navigate', (_, url) => {
    window.webContents.send('navigate-to', url);
  });

  ipcMain.handle('install-extension', async (_, extPath) => {
    try {
      const manifestPath = path.join(extPath, 'manifest.json');
      const analyzed = permissionManager.analyzePermissions(
        JSON.parse(require('fs').readFileSync(manifestPath, 'utf8'))
      );

      if (permissionManager.shouldPromptForPermissions(analyzed)) {
        const result = await dialog.showMessageBox(window, {
          type: 'warning',
          title: 'Extension Permissions',
          message: 'This extension requests high-risk permissions',
          detail: permissionManager.getPermissionPromptHTML(analyzed, extPath),
          buttons: ['Cancel', 'Install Anyway'],
          cancelId: 0,
        });

        if (result.response !== 1) {
          return { success: false, error: 'User cancelled' };
        }
      }

      const result = await session.defaultSession.loadExtension(extPath);
      return { success: true, result };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  ipcMain.handle('get-extensions', async () => {
    const extensions = session.defaultSession.getAllExtensions();
    return extensions.map(ext => ({
      id: ext.id,
      name: ext.name,
      version: ext.version,
      path: ext.path,
    }));
  });

  ipcMain.handle('remove-extension', async (_, extId) => {
    try {
      await session.defaultSession.removeExtension(extId);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  ipcMain.handle('privacy-stats', () => {
    return privacyShield.getStats();
  });

  ipcMain.handle('privacy-toggle', () => {
    return privacyShield.toggle();
  });

  ipcMain.handle('reading-mode-activate', async () => {
    const webContents = mainWindow.webContents;
    return readingMode.activate(webContents);
  });

  ipcMain.handle('reading-mode-deactivate', async () => {
    const webContents = mainWindow.webContents;
    return readingMode.deactivate(webContents);
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
}

function createNewTab() {
  if (mainWindow) {
    mainWindow.webContents.send('new-tab');
  }
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
