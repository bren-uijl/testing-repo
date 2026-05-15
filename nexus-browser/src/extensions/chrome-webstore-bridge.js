const { ipcMain, shell } = require('electron');

class ChromeWebStoreBridge {
  constructor(extensionManager) {
    this.extensionManager = extensionManager;
    this.setupIpcHandlers();
  }

  setupIpcHandlers() {
    ipcMain.handle('cws-search', async (_, query) => {
      return this.extensionManager.searchWebStore(query);
    });

    ipcMain.handle('cws-install', async (_, extensionId) => {
      try {
        const ext = await this.extensionManager.installFromWebStore(extensionId);
        return { success: true, extension: ext };
      } catch (error) {
        return { success: false, error: error.message };
      }
    });

    ipcMain.handle('cws-get-url', (_, extensionId) => {
      return this.extensionManager.getExtensionUrl(extensionId);
    });

    ipcMain.handle('cws-open-store', async (_, query) => {
      const url = query
        ? this.extensionManager.searchWebStore(query)
        : 'https://chrome.google.com/webstore/category/extensions';
      await shell.openExternal(url);
      return true;
    });

    ipcMain.handle('ext-list', async () => {
      return this.extensionManager.getInstalledExtensions();
    });

    ipcMain.handle('ext-uninstall', async (_, extId) => {
      return this.extensionManager.uninstallExtension(extId);
    });

    ipcMain.handle('ext-enable', async (_, extId) => {
      return this.extensionManager.enableExtension(extId);
    });

    ipcMain.handle('ext-disable', async (_, extId) => {
      return this.extensionManager.disableExtension(extId);
    });
  }

  interceptWebStoreRequests(webContents) {
    webContents.session.webRequest.onBeforeRequest((details, callback) => {
      const url = details.url;

      if (url.includes('chrome.google.com/webstore')) {
        const match = url.match(/\/detail\/([^/]+)\/([^?]+)/);
        if (match) {
          const extensionId = match[2];
          this.handleStorePageLoad(webContents, extensionId);
        }
      }

      callback({ cancel: false });
    });
  }

  async handleStorePageLoad(webContents, extensionId) {
    webContents.executeJavaScript(`
      (function() {
        const installBtn = document.querySelector('[data-item-id="install-button"]');
        if (installBtn) {
          installBtn.addEventListener('click', function(e) {
            e.preventDefault();
            window.postMessage({
              type: 'NEXUS_INSTALL_EXTENSION',
              extensionId: '${extensionId}'
            }, '*');
          });
        }
      })();
    `);
  }
}

module.exports = ChromeWebStoreBridge;
