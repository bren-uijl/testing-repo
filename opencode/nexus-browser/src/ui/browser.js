class BrowserApp {
  constructor() {
    this.tabs = [];
    this.activeTabId = null;
    this.tabCounter = 0;

    this.initWindowControls();
    this.initTabBar();
    this.initNavigation();
    this.initPanels();
    this.initKeyboardShortcuts();
    this.loadPrivacyStats();

    this.createTab();
  }

  initWindowControls() {
    document.getElementById('minimize-btn').addEventListener('click', () => {
      window.electronAPI.windowControls.minimize();
    });
    document.getElementById('maximize-btn').addEventListener('click', () => {
      window.electronAPI.windowControls.maximize();
    });
    document.getElementById('close-btn').addEventListener('click', () => {
      window.electronAPI.windowControls.close();
    });
  }

  initTabBar() {
    document.getElementById('new-tab-btn').addEventListener('click', () => {
      this.createTab();
    });
  }

  initNavigation() {
    const urlBar = document.getElementById('url-bar');
    const homeSearch = document.getElementById('home-search');

    urlBar.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        this.navigate(urlBar.value);
      }
    });

    homeSearch.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        this.navigate(homeSearch.value);
      }
    });

    document.getElementById('back-btn').addEventListener('click', () => {
      const webview = document.getElementById('webview');
      if (webview.canGoBack()) webview.goBack();
    });

    document.getElementById('forward-btn').addEventListener('click', () => {
      const webview = document.getElementById('webview');
      if (webview.canGoForward()) webview.goForward();
    });

    document.getElementById('refresh-btn').addEventListener('click', () => {
      const webview = document.getElementById('webview');
      webview.reload();
    });

    document.getElementById('home-btn').addEventListener('click', () => {
      this.goHome();
    });

    document.getElementById('reading-mode-btn').addEventListener('click', () => {
      this.togglePanel('reading-panel');
      this.activateReadingMode();
    });

    document.getElementById('privacy-btn').addEventListener('click', () => {
      this.togglePanel('privacy-panel');
    });

    document.getElementById('downloads-btn').addEventListener('click', () => {
      this.togglePanel('downloads-panel');
      this.loadDownloads();
    });

    document.getElementById('extensions-btn').addEventListener('click', () => {
      this.togglePanel('extensions-panel');
      this.loadExtensions();
    });

    document.getElementById('passwords-btn').addEventListener('click', () => {
      this.togglePanel('passwords-panel');
      this.loadPasswords();
    });

    document.getElementById('settings-btn').addEventListener('click', () => {
      this.togglePanel('settings-panel');
    });
  }

  initPanels() {
    document.querySelectorAll('.close-panel-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        btn.closest('.side-panel').classList.add('hidden');
      });
    });

    document.getElementById('privacy-toggle').addEventListener('change', async (e) => {
      await window.electronAPI.privacy.toggle(e.target.checked);
      this.updatePrivacyIndicator(e.target.checked);
    });

    document.getElementById('add-domain-btn').addEventListener('click', async () => {
      const input = document.getElementById('new-domain');
      const domain = input.value.trim();
      if (domain) {
        const domains = await window.electronAPI.privacy.addBlockedDomain(domain);
        this.updateBlockedDomainsList(domains);
        input.value = '';
      }
    });

    document.getElementById('install-extension-btn').addEventListener('click', () => {
      document.getElementById('extension-modal').classList.remove('hidden');
    });

    document.getElementById('modal-cancel-btn').addEventListener('click', () => {
      document.getElementById('extension-modal').classList.add('hidden');
    });

    document.getElementById('modal-install-btn').addEventListener('click', async () => {
      const extensionId = document.getElementById('extension-id-input').value.trim();
      if (extensionId) {
        const result = await window.electronAPI.extensions.installFromWebStore(extensionId);
        if (result) {
          this.loadExtensions();
        }
        document.getElementById('extension-modal').classList.add('hidden');
        document.getElementById('extension-id-input').value = '';
      }
    });

    document.getElementById('load-unpacked-btn').addEventListener('click', async () => {
      const result = await window.electronAPI.extensions.loadUnpacked();
      if (result) {
        this.loadExtensions();
      }
    });

    document.getElementById('clear-downloads-btn').addEventListener('click', async () => {
      await window.electronAPI.downloads.clearDownloads();
      this.loadDownloads();
    });

    document.getElementById('save-settings-btn').addEventListener('click', async () => {
      const settings = {
        privacy: {
          blockTrackers: document.getElementById('setting-block-trackers').checked,
          blockAds: document.getElementById('setting-block-ads').checked
        },
        downloads: {
          askDownloadPath: document.getElementById('setting-ask-download-path').checked
        },
        appearance: {
          showHome: document.getElementById('setting-show-home').checked
        }
      };
      await window.electronAPI.settings.saveSettings(settings);
    });

    document.getElementById('export-passwords-btn').addEventListener('click', async () => {
      const masterPassword = prompt('Enter master password to export:');
      if (masterPassword) {
        await window.electronAPI.passwords.exportPasswords(masterPassword);
      }
    });

    document.getElementById('import-passwords-btn').addEventListener('click', async () => {
      const masterPassword = prompt('Enter master password to import:');
      if (masterPassword) {
        const result = await window.electronAPI.passwords.importPasswords('', masterPassword);
        if (result) {
          this.loadPasswords();
        }
      }
    });
  }

  initKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
      if (e.ctrlKey || e.metaKey) {
        switch (e.key.toLowerCase()) {
          case 't':
            e.preventDefault();
            this.createTab();
            break;
          case 'w':
            e.preventDefault();
            this.closeTab(this.activeTabId);
            break;
          case 'l':
            e.preventDefault();
            document.getElementById('url-bar').focus();
            break;
          case 'r':
            e.preventDefault();
            document.getElementById('webview').reload();
            break;
        }
      }
    });
  }

  createTab(url = null) {
    const tabId = ++this.tabCounter;
    const tab = {
      id: tabId,
      title: 'New Tab',
      url: url || '',
      loading: false
    };

    this.tabs.push(tab);
    this.renderTabs();
    this.switchTab(tabId);

    if (url) {
      this.navigate(url);
    } else {
      this.goHome();
    }
  }

  closeTab(tabId) {
    const index = this.tabs.findIndex(t => t.id === tabId);
    if (index === -1) return;

    this.tabs.splice(index, 1);

    if (this.tabs.length === 0) {
      this.createTab();
      return;
    }

    if (this.activeTabId === tabId) {
      const newIndex = Math.min(index, this.tabs.length - 1);
      this.switchTab(this.tabs[newIndex].id);
    }

    this.renderTabs();
  }

  switchTab(tabId) {
    this.activeTabId = tabId;
    const tab = this.tabs.find(t => t.id === tabId);

    this.renderTabs();

    if (tab && tab.url) {
      document.getElementById('url-bar').value = tab.url;
      document.getElementById('webview').src = tab.url;
      document.getElementById('webview').classList.add('visible');
      document.getElementById('home-page').classList.add('hidden');
    } else {
      this.goHome();
    }
  }

  renderTabs() {
    const tabsContainer = document.getElementById('tabs');
    tabsContainer.innerHTML = '';

    this.tabs.forEach(tab => {
      const tabEl = document.createElement('div');
      tabEl.className = `tab ${tab.id === this.activeTabId ? 'active' : ''}`;
      tabEl.innerHTML = `
        <span class="tab-title">${tab.loading ? 'Loading...' : tab.title}</span>
        <button class="tab-close" data-tab-id="${tab.id}">&times;</button>
      `;
      tabEl.addEventListener('click', (e) => {
        if (!e.target.classList.contains('tab-close')) {
          this.switchTab(tab.id);
        }
      });
      tabEl.querySelector('.tab-close').addEventListener('click', (e) => {
        e.stopPropagation();
        this.closeTab(tab.id);
      });
      tabsContainer.appendChild(tabEl);
    });
  }

  navigate(input) {
    let url = input.trim();

    if (!url) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.includes('.') && !url.includes(' ')) {
        url = 'https://' + url;
      } else {
        url = 'https://www.google.com/search?q=' + encodeURIComponent(url);
      }
    }

    const webview = document.getElementById('webview');
    const urlBar = document.getElementById('url-bar');

    urlBar.value = url;
    webview.src = url;
    webview.classList.add('visible');
    document.getElementById('home-page').classList.add('hidden');

    const tab = this.tabs.find(t => t.id === this.activeTabId);
    if (tab) {
      tab.url = url;
      tab.loading = true;
      this.renderTabs();
    }

    webview.addEventListener('did-finish-load', () => {
      if (tab) tab.loading = false;
      this.renderTabs();
    }, { once: true });

    webview.addEventListener('page-title-updated', (e) => {
      if (tab) {
        tab.title = e.title;
        this.renderTabs();
      }
    });
  }

  goHome() {
    document.getElementById('webview').classList.remove('visible');
    document.getElementById('home-page').classList.remove('hidden');
    document.getElementById('url-bar').value = '';

    const tab = this.tabs.find(t => t.id === this.activeTabId);
    if (tab) {
      tab.url = '';
      tab.title = 'New Tab';
      this.renderTabs();
    }
  }

  togglePanel(panelId) {
    const panel = document.getElementById(panelId);
    const isHidden = panel.classList.contains('hidden');

    document.querySelectorAll('.side-panel').forEach(p => p.classList.add('hidden'));

    if (isHidden) {
      panel.classList.remove('hidden');
    }
  }

  async loadPrivacyStats() {
    const stats = await window.electronAPI.privacy.getStats();
    document.getElementById('blocked-count').textContent = stats.blockedCount || 0;

    const domains = await window.electronAPI.privacy.getBlockedDomains();
    this.updateBlockedDomainsList(domains);
  }

  updateBlockedDomainsList(domains) {
    const list = document.getElementById('blocked-domains-list');
    list.innerHTML = '';
    domains.forEach(domain => {
      const li = document.createElement('li');
      li.innerHTML = `
        <span>${domain}</span>
        <button data-domain="${domain}">&times;</button>
      `;
      li.querySelector('button').addEventListener('click', async () => {
        const updatedDomains = await window.electronAPI.privacy.removeBlockedDomain(domain);
        this.updateBlockedDomainsList(updatedDomains);
      });
      list.appendChild(li);
    });
  }

  updatePrivacyIndicator(active) {
    const indicator = document.getElementById('privacy-indicator');
    if (active) {
      indicator.classList.add('active');
      indicator.innerHTML = `
        <svg width="12" height="12" viewBox="0 0 16 16"><path d="M8 1L2 4v4c0 4 6 7 6 7s6-3 6-7V4L8 1z" fill="currentColor"/></svg>
        Shield Active
      `;
    } else {
      indicator.classList.remove('active');
      indicator.innerHTML = `
        <svg width="12" height="12" viewBox="0 0 16 16"><path d="M8 1L2 4v4c0 4 6 7 6 7s6-3 6-7V4L8 1z" fill="currentColor"/></svg>
        Shield Off
      `;
    }
  }

  async loadDownloads() {
    const downloads = await window.electronAPI.downloads.getDownloads();
    const list = document.getElementById('downloads-list');
    list.innerHTML = '';

    downloads.forEach(download => {
      const item = document.createElement('div');
      item.className = 'download-item';
      item.innerHTML = `
        <div class="name">${download.filename}</div>
        <div class="download-progress">
          <div class="download-progress-bar" style="width: ${download.progress}%"></div>
        </div>
        <div class="download-actions">
          ${download.state === 'downloading' ? `
            <button onclick="window.browserApp.pauseDownload('${download.id}')">Pause</button>
            <button onclick="window.browserApp.cancelDownload('${download.id}')">Cancel</button>
          ` : download.state === 'paused' ? `
            <button onclick="window.browserApp.resumeDownload('${download.id}')">Resume</button>
          ` : `
            <button onclick="window.browserApp.openDownload('${download.id}')">Open</button>
          `}
        </div>
      `;
      list.appendChild(item);
    });
  }

  async pauseDownload(id) {
    await window.electronAPI.downloads.pauseDownload(id);
    this.loadDownloads();
  }

  async resumeDownload(id) {
    await window.electronAPI.downloads.resumeDownload(id);
    this.loadDownloads();
  }

  async cancelDownload(id) {
    await window.electronAPI.downloads.cancelDownload(id);
    this.loadDownloads();
  }

  async openDownload(id) {
    await window.electronAPI.downloads.openDownload(id);
  }

  async activateReadingMode() {
    const webview = document.getElementById('webview');
    try {
      const html = await webview.executeJavaScript('document.documentElement.outerHTML');
      const article = await window.electronAPI.readingMode.extractArticle(html);
      if (article) {
        document.getElementById('reading-content').innerHTML = `
          <h2>${article.title}</h2>
          <p>${article.content}</p>
        `;
      } else {
        document.getElementById('reading-content').innerHTML = '<p>No article content detected on this page.</p>';
      }
    } catch (e) {
      document.getElementById('reading-content').innerHTML = '<p>Unable to extract article content.</p>';
    }
  }

  async loadExtensions() {
    const extensions = await window.electronAPI.extensions.getExtensions();
    const list = document.getElementById('extensions-list');
    list.innerHTML = '';

    extensions.forEach(ext => {
      const item = document.createElement('div');
      item.className = 'extension-item';
      item.innerHTML = `
        <div class="extension-icon">${ext.icon || '🧩'}</div>
        <div class="extension-info">
          <div class="name">${ext.name}</div>
          <div class="version">v${ext.version}</div>
        </div>
        <label class="extension-toggle">
          <input type="checkbox" ${ext.enabled ? 'checked' : ''} onchange="window.browserApp.toggleExtension('${ext.id}', this.checked)">
          <span class="slider"></span>
        </label>
        <button class="extension-uninstall" onclick="window.browserApp.uninstallExtension('${ext.id}')">&times;</button>
      `;
      list.appendChild(item);
    });
  }

  async toggleExtension(id, enabled) {
    await window.electronAPI.extensions.toggleExtension(id, enabled);
  }

  async uninstallExtension(id) {
    await window.electronAPI.extensions.uninstallExtension(id);
    this.loadExtensions();
  }

  async loadPasswords() {
    const passwords = await window.electronAPI.passwords.getPasswords();
    const list = document.getElementById('passwords-list');
    list.innerHTML = '';

    passwords.forEach(pwd => {
      const item = document.createElement('div');
      item.className = 'password-item';
      item.innerHTML = `
        <div class="password-icon">🔒</div>
        <div class="password-info">
          <div class="site">${pwd.site}</div>
          <div class="username">${pwd.username}</div>
        </div>
        <button class="password-delete" onclick="window.browserApp.deletePassword('${pwd.id}')">&times;</button>
      `;
      list.appendChild(item);
    });
  }

  async deletePassword(id) {
    await window.electronAPI.passwords.deletePassword(id);
    this.loadPasswords();
  }
}

document.addEventListener('DOMContentLoaded', () => {
  window.browserApp = new BrowserApp();
});
