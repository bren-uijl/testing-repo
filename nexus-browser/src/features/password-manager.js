const { app, ipcMain, dialog } = require('electron');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class PasswordManager {
  constructor() {
    this.vaultPath = path.join(app.getPath('userData'), 'passwords.enc');
    this.passwords = [];
    this.isUnlocked = false;
    this.masterKey = null;

    this.setupIpcHandlers();
  }

  setupIpcHandlers() {
    ipcMain.handle('passwords-save', async (_, entry) => {
      return this.savePassword(entry);
    });

    ipcMain.handle('passwords-get', async (_, url) => {
      return this.getPasswordsForUrl(url);
    });

    ipcMain.handle('passwords-list', async () => {
      return this.getPasswordList();
    });

    ipcMain.handle('passwords-delete', async (_, id) => {
      return this.deletePassword(id);
    });

    ipcMain.handle('passwords-unlock', async (_, masterPassword) => {
      return this.unlock(masterPassword);
    });

    ipcMain.handle('passwords-export', async () => {
      return this.exportPasswords();
    });

    ipcMain.handle('passwords-import', async (_, data) => {
      return this.importPasswords(data);
    });
  }

  deriveKey(password, salt) {
    return crypto.pbkdf2Sync(password, salt, 100000, 32, 'sha256');
  }

  encrypt(data, key) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    let encrypted = cipher.update(JSON.stringify(data), 'utf8', 'hex');
    encrypted += cipher.final('hex');
    const authTag = cipher.getAuthTag();
    return {
      iv: iv.toString('hex'),
      data: encrypted,
      authTag: authTag.toString('hex'),
    };
  }

  decrypt(encrypted, key) {
    const decipher = crypto.createDecipheriv(
      'aes-256-gcm',
      key,
      Buffer.from(encrypted.iv, 'hex')
    );
    decipher.setAuthTag(Buffer.from(encrypted.authTag, 'hex'));
    let decrypted = decipher.update(encrypted.data, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return JSON.parse(decrypted);
  }

  async unlock(masterPassword) {
    try {
      let salt, encrypted;

      if (fs.existsSync(this.vaultPath)) {
        const vaultData = JSON.parse(fs.readFileSync(this.vaultPath, 'utf8'));
        salt = Buffer.from(vaultData.salt, 'hex');
        encrypted = vaultData.encrypted;
      } else {
        salt = crypto.randomBytes(16);
        this.passwords = [];
      }

      this.masterKey = this.deriveKey(masterPassword, salt);

      if (encrypted) {
        this.passwords = this.decrypt(encrypted, this.masterKey);
      }

      this.isUnlocked = true;
      return { success: true };
    } catch (error) {
      return { success: false, error: 'Incorrect master password' };
    }
  }

  savePassword(entry) {
    if (!this.isUnlocked) return { success: false, error: 'Vault locked' };

    const existingIndex = this.passwords.findIndex(
      p => p.url === entry.url && p.username === entry.username
    );

    const passwordEntry = {
      id: existingIndex >= 0 ? this.passwords[existingIndex].id : crypto.randomUUID(),
      url: entry.url,
      username: entry.username,
      password: entry.password,
      title: entry.title || new URL(entry.url).hostname,
      createdAt: existingIndex >= 0 ? this.passwords[existingIndex].createdAt : Date.now(),
      updatedAt: Date.now(),
    };

    if (existingIndex >= 0) {
      this.passwords[existingIndex] = passwordEntry;
    } else {
      this.passwords.push(passwordEntry);
    }

    this.saveVault();
    return { success: true, id: passwordEntry.id };
  }

  getPasswordsForUrl(url) {
    if (!this.isUnlocked) return [];

    const hostname = new URL(url).hostname;
    return this.passwords.filter(p =>
      p.url.includes(hostname) || hostname.includes(p.url)
    );
  }

  getPasswordList() {
    if (!this.isUnlocked) return [];

    return this.passwords.map(p => ({
      id: p.id,
      url: p.url,
      username: p.username,
      title: p.title,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    }));
  }

  deletePassword(id) {
    if (!this.isUnlocked) return { success: false, error: 'Vault locked' };

    this.passwords = this.passwords.filter(p => p.id !== id);
    this.saveVault();
    return { success: true };
  }

  saveVault() {
    if (!this.masterKey) return;

    const salt = crypto.randomBytes(16);
    const key = this.deriveKey(
      this.masterKey.toString('hex'),
      salt
    );
    const encrypted = this.encrypt(this.passwords, key);

    fs.writeFileSync(
      this.vaultPath,
      JSON.stringify({
        salt: salt.toString('hex'),
        encrypted,
      })
    );
  }

  async exportPasswords() {
    if (!this.isUnlocked) return { success: false, error: 'Vault locked' };

    const result = await dialog.showSaveDialog({
      title: 'Export Passwords',
      defaultPath: 'nexus-passwords.csv',
      filters: [{ name: 'CSV', extensions: ['csv'] }],
    });

    if (!result.canceled && result.filePath) {
      const csv = [
        'URL,Username,Password,Title',
        ...this.passwords.map(p =>
          `"${p.url}","${p.username}","${p.password}","${p.title}"`
        ),
      ].join('\n');

      fs.writeFileSync(result.filePath, csv);
      return { success: true, path: result.filePath };
    }

    return { success: false, error: 'Cancelled' };
  }

  async importPasswords(csvData) {
    if (!this.isUnlocked) return { success: false, error: 'Vault locked' };

    const lines = csvData.split('\n').slice(1);
    let imported = 0;

    for (const line of lines) {
      const match = line.match(/"([^"]*)","([^"]*)","([^"]*)","([^"]*)"/);
      if (match) {
        this.savePassword({
          url: match[1],
          username: match[2],
          password: match[3],
          title: match[4],
        });
        imported++;
      }
    }

    return { success: true, imported };
  }
}

module.exports = PasswordManager;
