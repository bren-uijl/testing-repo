const { app, BrowserWindow, session, ipcMain, dialog, nativeTheme } = require('electron');
const path = require('path');
const Store = require('electron-store');

const store = new Store();

let mainWindow;
let browserWindows = [];

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

  setupExtensionSupport(mainWindow);
  setupIpcHandlers(mainWindow);

  return mainWindow;
}

function setupExtensionSupport(window) {
  const extPath = path.join(app.getPath('userData'), 'extensions');

  session.defaultSession.loadExtension(extPath).catch(() => {});

  session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
    if (details.url.includes('chrome-extension://')) {
      callback({ cancel: false });
    } else {
      callback({});
    }
  });
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
