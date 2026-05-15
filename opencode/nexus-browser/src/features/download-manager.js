const fs = require('fs');
const path = require('path');
const { shell } = require('electron');

class DownloadManager {
  constructor(mainWindow, downloadsPath) {
    this.mainWindow = mainWindow;
    this.downloadsPath = downloadsPath;
    this.downloads = new Map();
    this.downloadCounter = 0;
    this.settingsPath = path.join(require('electron').app.getPath('userData'), 'download-settings.json');

    this.settings = {
      askDownloadPath: false,
      defaultPath: downloadsPath
    };

    this.loadSettings();
    this.setupDownloadListener();
  }

  loadSettings() {
    try {
      if (fs.existsSync(this.settingsPath)) {
        this.settings = { ...this.settings, ...JSON.parse(fs.readFileSync(this.settingsPath, 'utf8')) };
      }
    } catch (err) {
      console.error('Failed to load download settings:', err);
    }
  }

  saveSettings(additionalSettings = {}) {
    this.settings = { ...this.settings, ...additionalSettings };
    try {
      fs.writeFileSync(this.settingsPath, JSON.stringify(this.settings, null, 2));
    } catch (err) {
      console.error('Failed to save download settings:', err);
    }
  }

  setupDownloadListener() {
    this.mainWindow.webContents.session.on('will-download', (event, item, webContents) => {
      const downloadId = `dl_${++this.downloadCounter}`;

      const downloadInfo = {
        id: downloadId,
        filename: item.getFilename(),
        url: item.getURL(),
        totalBytes: item.getTotalBytes(),
        receivedBytes: 0,
        progress: 0,
        state: 'downloading',
        startTime: Date.now(),
        path: path.join(this.downloadsPath, item.getFilename())
      };

      this.downloads.set(downloadId, downloadInfo);

      if (this.settings.askDownloadPath) {
        const savePath = this.promptSavePath(item.getFilename());
        if (savePath) {
          item.setSavePath(savePath);
          downloadInfo.path = savePath;
        }
      } else {
        item.setSavePath(downloadInfo.path);
      }

      item.on('updated', (event, state) => {
        downloadInfo.receivedBytes = item.getReceivedBytes();
        downloadInfo.progress = downloadInfo.totalBytes > 0
          ? Math.round((downloadInfo.receivedBytes / downloadInfo.totalBytes) * 100)
          : 0;

        if (state === 'interrupted') {
          downloadInfo.state = 'paused';
        }
      });

      item.on('done', (event, state) => {
        if (state === 'completed') {
          downloadInfo.state = 'completed';
          downloadInfo.progress = 100;
          downloadInfo.completedTime = Date.now();
        } else {
          downloadInfo.state = 'cancelled';
        }
      });
    });
  }

  promptSavePath(filename) {
    const result = require('electron').dialog.showSaveDialogSync(this.mainWindow, {
      title: 'Save Download',
      defaultPath: path.join(this.downloadsPath, filename)
    });
    return result;
  }

  getDownloads() {
    return Array.from(this.downloads.values()).map(d => ({
      id: d.id,
      filename: d.filename,
      url: d.url,
      totalBytes: d.totalBytes,
      receivedBytes: d.receivedBytes,
      progress: d.progress,
      state: d.state,
      path: d.path
    }));
  }

  pauseDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (download && download.state === 'downloading') {
      download.state = 'paused';
      return true;
    }
    return false;
  }

  resumeDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (download && download.state === 'paused') {
      download.state = 'downloading';
      return true;
    }
    return false;
  }

  cancelDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (download) {
      download.state = 'cancelled';
      if (fs.existsSync(download.path)) {
        fs.unlinkSync(download.path);
      }
      return true;
    }
    return false;
  }

  async openDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (download && fs.existsSync(download.path)) {
      await shell.openPath(download.path);
      return true;
    }
    return false;
  }

  clearDownloads() {
    this.downloads.clear();
    return true;
  }

  getSettings() {
    return this.settings;
  }

  saveSettings(settings) {
    this.saveSettings(settings);
  }
}

module.exports = DownloadManager;
