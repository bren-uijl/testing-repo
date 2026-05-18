const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { dialog } = require('electron');

class PasswordManager {
  constructor(userDataPath) {
    this.vaultPath = path.join(userDataPath, 'password-vault.json');
    this.passwords = new Map();
    this.masterKey = null;
    this.isUnlocked = false;

    this.loadVault();
  }

  loadVault() {
    try {
      if (fs.existsSync(this.vaultPath)) {
        const data = JSON.parse(fs.readFileSync(this.vaultPath, 'utf8'));
        if (data.entries) {
          data.entries.forEach(entry => {
            this.passwords.set(entry.id, entry);
          });
        }
      }
    } catch (err) {
      console.error('Failed to load password vault:', err);
    }
  }

  saveVault() {
    const data = {
      version: 1,
      entries: Array.from(this.passwords.values()),
      lastUpdated: new Date().toISOString(),
    };

    try {
      fs.writeFileSync(this.vaultPath, JSON.stringify(data, null, 2));
    } catch (err) {
      console.error('Failed to save password vault:', err);
    }
  }

  deriveKey(password, salt) {
    return crypto.pbkdf2Sync(password, salt, 100000, 32, 'sha256');
  }

  encrypt(text, key) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authTag = cipher.getAuthTag();

    return {
      encrypted,
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex'),
    };
  }

  decrypt(encryptedData, key) {
    const iv = Buffer.from(encryptedData.iv, 'hex');
    const authTag = Buffer.from(encryptedData.authTag, 'hex');

    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
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
        this.passwords = new Map();
      }

      this.masterKey = this.deriveKey(masterPassword, salt);

      if (encrypted) {
        const decrypted = this.decrypt(encrypted, this.masterKey);
        decrypted.forEach(entry => {
          this.passwords.set(entry.id, entry);
        });
      }

      this.isUnlocked = true;
      return { success: true };
    } catch (error) {
      return { success: false, error: 'Incorrect master password' };
    }
  }

  encryptPassword(password) {
    const key = crypto.randomBytes(32);
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

    let encrypted = cipher.update(password, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authTag = cipher.getAuthTag();

    return {
      encrypted,
      key: key.toString('hex'),
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex'),
    };
  }

  decryptPassword(encryptedData) {
    const key = Buffer.from(encryptedData.key, 'hex');
    const iv = Buffer.from(encryptedData.iv, 'hex');
    const authTag = Buffer.from(encryptedData.authTag, 'hex');

    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  }

  async savePassword(site, username, password) {
    const id = `pwd_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    const entry = {
      id,
      site,
      username,
      password: this.encryptPassword(password),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    this.passwords.set(id, entry);
    this.saveVault();

    return entry;
  }

  getPasswords() {
    return Array.from(this.passwords.values()).map(p => ({
      id: p.id,
      site: p.site,
      username: p.username,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    }));
  }

  getPassword(id) {
    const entry = this.passwords.get(id);
    if (entry) {
      return {
        ...entry,
        password: this.decryptPassword(entry.password),
      };
    }
    return null;
  }

  async deletePassword(id) {
    return this.passwords.delete(id);
  }

  findPasswordsForSite(site) {
    return Array.from(this.passwords.values())
      .filter(p => p.site.toLowerCase().includes(site.toLowerCase()))
      .map(p => ({
        id: p.id,
        site: p.site,
        username: p.username,
      }));
  }

  async exportToCSV(filePath, masterPassword) {
    try {
      const csvHeader = 'Site,Username,Password\n';
      const csvRows = Array.from(this.passwords.values()).map(p => {
        const password = this.decryptPassword(p.password);
        return `"${p.site}","${p.username}","${password}"`;
      });

      const csvContent = csvHeader + csvRows.join('\n');

      const salt = crypto.randomBytes(16);
      const key = this.deriveKey(masterPassword, salt);
      const encrypted = this.encrypt(csvContent, key);

      const exportData = {
        version: 1,
        salt: salt.toString('hex'),
        ...encrypted,
        exportedAt: new Date().toISOString(),
      };

      fs.writeFileSync(filePath, JSON.stringify(exportData, null, 2));
      return true;
    } catch (err) {
      console.error('Failed to export passwords:', err);
      return false;
    }
  }

  async importFromCSV(filePath, masterPassword) {
    try {
      const content = fs.readFileSync(filePath, 'utf8');

      let csvContent;
      try {
        const data = JSON.parse(content);
        const salt = Buffer.from(data.salt, 'hex');
        const key = this.deriveKey(masterPassword, salt);
        csvContent = this.decrypt(data, key);
      } catch {
        csvContent = content;
      }

      const lines = csvContent.split('\n').filter(line => line.trim());

      if (lines.length < 2) return false;

      for (let i = 1; i < lines.length; i++) {
        const match = lines[i].match(/"([^"]*)","([^"]*)","([^"]*)"/);
        if (match) {
          const [, site, username, password] = match;
          await this.savePassword(site, username, password);
        }
      }

      return true;
    } catch (err) {
      console.error('Failed to import passwords:', err);
      return false;
    }
  }
}

module.exports = PasswordManager;
