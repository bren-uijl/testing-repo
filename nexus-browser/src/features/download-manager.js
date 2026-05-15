const { app, ipcMain, shell } = require('electron');
const fs = require('fs');
const path = require('path');

class DownloadManager {
  constructor() {
    this.downloads = new Map();
    this.downloadDir = path.join(app.getPath('downloads'), 'Nexus');
    this.setupDownloadDir();
    this.setupIpcHandlers();
  }

  setupDownloadDir() {
    if (!fs.existsSync(this.downloadDir)) {
      fs.mkdirSync(this.downloadDir, { recursive: true });
    }
  }

  setupIpcHandlers() {
    ipcMain.handle('downloads-list', () => {
      return this.getDownloads();
    });

    ipcMain.handle('downloads-open', (_, downloadId) => {
      return this.openDownload(downloadId);
    });

    ipcMain.handle('downloads-open-folder', () => {
      return shell.openPath(this.downloadDir);
    });

    ipcMain.handle('downloads-clear', () => {
      return this.clearCompleted();
    });

    ipcMain.handle('downloads-cancel', (_, downloadId) => {
      return this.cancelDownload(downloadId);
    });

    ipcMain.handle('downloads-retry', (_, downloadId) => {
      return this.retryDownload(downloadId);
    });
  }

  registerDownload(webContents, downloadItem) {
    const downloadId = Date.now().toString();
    const filename = downloadItem.getFilename();
    const savePath = path.join(this.downloadDir, filename);

    downloadItem.setSavePath(savePath);

    const downloadInfo = {
      id: downloadId,
      filename,
      url: downloadItem.getURL(),
      savePath,
      state: 'progressing',
      receivedBytes: 0,
      totalBytes: downloadItem.getTotalBytes(),
      startTime: Date.now(),
      endTime: null,
      error: null,
    };

    this.downloads.set(downloadId, downloadInfo);

    downloadItem.on('updated', (event, state) => {
      downloadInfo.state = state;
      downloadInfo.receivedBytes = downloadItem.getReceivedBytes();
      downloadInfo.totalBytes = downloadItem.getTotalBytes();

      this.notifyProgress(downloadId, downloadInfo);
    });

    downloadItem.on('done', (event, state) => {
      downloadInfo.state = state === 'completed' ? 'completed' : 'cancelled';
      downloadInfo.endTime = Date.now();
      downloadInfo.receivedBytes = downloadItem.getReceivedBytes();

      if (state === 'completed') {
        this.notifyComplete(downloadId, downloadInfo);
      } else {
        downloadInfo.error = 'Download cancelled';
        this.notifyError(downloadId, downloadInfo);
      }
    });

    this.notifyStart(downloadId, downloadInfo);

    return downloadId;
  }

  getDownloads() {
    return Array.from(this.downloads.values())
      .sort((a, b) => b.startTime - a.startTime)
      .map(d => ({
        ...d,
        progress: d.totalBytes > 0 ? Math.round((d.receivedBytes / d.totalBytes) * 100) : 0,
      }));
  }

  async openDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (!download || download.state !== 'completed') return false;

    try {
      await shell.openPath(download.savePath);
      return true;
    } catch {
      return false;
    }
  }

  async cancelDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (!download) return false;

    download.state = 'cancelled';
    download.endTime = Date.now();

    return true;
  }

  async retryDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (!download) return false;

    download.state = 'pending';
    download.error = null;
    download.receivedBytes = 0;

    return true;
  }

  clearCompleted() {
    for (const [id, download] of this.downloads) {
      if (download.state === 'completed' || download.state === 'cancelled') {
        this.downloads.delete(id);
      }
    }
    return true;
  }

  notifyStart(id, info) {
    this.sendToAllWindows('download-started', { id, ...info });
  }

  notifyProgress(id, info) {
    this.sendToAllWindows('download-progress', {
      id,
      progress: info.totalBytes > 0 ? Math.round((info.receivedBytes / info.totalBytes) * 100) : 0,
      receivedBytes: info.receivedBytes,
      totalBytes: info.totalBytes,
    });
  }

  notifyComplete(id, info) {
    this.sendToAllWindows('download-completed', {
      id,
      filename: info.filename,
      savePath: info.savePath,
    });
  }

  notifyError(id, info) {
    this.sendToAllWindows('download-error', {
      id,
      error: info.error,
    });
  }

  sendToAllWindows(channel, data) {
    const { BrowserWindow } = require('electron');
    const windows = BrowserWindow.getAllWindows();
    for (const win of windows) {
      win.webContents.send(channel, data);
    }
  }
}

module.exports = DownloadManager;
