const DEFAULT_HOME_PAGE = 'nexus://home';
const SEARCH_ENGINE_URL = 'https://www.google.com/search?q=';

const QUICK_LINKS = [
  { title: 'Google', url: 'https://google.com', icon: 'G' },
  { title: 'YouTube', url: 'https://youtube.com', icon: 'Y' },
  { title: 'GitHub', url: 'https://github.com', icon: 'GH' },
  { title: 'Reddit', url: 'https://reddit.com', icon: 'R' },
  { title: 'Wikipedia', url: 'https://wikipedia.org', icon: 'W' },
];

class NexusBrowser {
  constructor() {
    this.tabs = [];
    this.activeTabId = null;
    this.tabCounter = 0;
    this.bookmarks = JSON.parse(localStorage.getItem('nexus_bookmarks') || '[]');
    this.zoomLevel = 1.0;

    this.init();
  }

  init() {
    this.cacheElements();
    this.bindEvents();
    this.loadQuickLinks();
    this.createTab();
    this.updateZoomDisplay();
    this.loadPrivacyStats();
  }

  cacheElements() {
    this.urlInput = document.getElementById('url-bar');
    this.homeSearch = document.getElementById('home-search');
    this.tabsContainer = document.getElementById('tabs');
    this.webviewContainer = document.getElementById('webview-container');
    this.homePage = document.getElementById('home-page');
    this.statusText = document.getElementById('status-text');
    this.zoomDisplay = document.getElementById('zoom-level');
    this.securityIcon = document.getElementById('security-icon');
    this.starBtn = document.getElementById('star-btn');

    this.extensionsPanel = document.getElementById('extensions-panel');
    this.bookmarksPanel = document.getElementById('bookmarks-panel');
    this.menuPanel = document.getElementById('menu-panel');
    this.privacyPanel = document.getElementById('privacy-panel');
    this.downloadsPanel = document.getElementById('downloads-panel');
    this.passwordsPanel = document.getElementById('passwords-panel');
    this.settingsPanel = document.getElementById('settings-panel');
    this.readingPanel = document.getElementById('reading-panel');

    this.installedExtensions = document.getElementById('extensions-list');
    this.bookmarksList = document.getElementById('bookmarks-list');
    this.quickLinksContainer = document.getElementById('quick-links');
  }

  bindEvents() {
    this.urlInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        this.navigate(this.urlInput.value);
        this.urlInput.blur();
      }
    });

    this.urlInput.addEventListener('focus', () => {
      this.urlInput.select();
    });

    this.homeSearch.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        this.navigate(this.homeSearch.value);
      }
    });

    document.getElementById('back-btn').addEventListener('click', () => this.goBack());
    document.getElementById('forward-btn').addEventListener('click', () => this.goForward());
    document.getElementById('refresh-btn').addEventListener('click', () => this.refresh());
    document.getElementById('home-btn').addEventListener('click', () => this.goHome());
    document.getElementById('new-tab-btn').addEventListener('click', () => this.createTab());
    this.starBtn.addEventListener('click', () => this.toggleBookmark());

    document.getElementById('extensions-btn').addEventListener('click', () => this.togglePanel('extensions'));
    document.getElementById('downloads-btn').addEventListener('click', () => { this.togglePanel('downloads'); this.loadDownloads(); });
    document.getElementById('passwords-btn').addEventListener('click', () => { this.togglePanel('passwords'); this.loadPasswords(); });
    document.getElementById('bookmarks-btn').addEventListener('click', () => this.togglePanel('bookmarks'));
    document.getElementById('menu-btn').addEventListener('click', () => this.togglePanel('menu'));
    document.getElementById('privacy-btn').addEventListener('click', () => this.togglePanel('privacy'));
    document.getElementById('reading-mode-btn').addEventListener('click', () => this.togglePanel('reading'));

    document.querySelectorAll('.close-panel-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        btn.closest('.side-panel, .dropdown-panel').classList.add('hidden');
      });
    });

    document.getElementById('install-extension-btn').addEventListener('click', () => {
      document.getElementById('extension-modal').classList.remove('hidden');
    });

    document.getElementById('modal-cancel-btn').addEventListener('click', () => {
      document.getElementById('extension-modal').classList.add('hidden');
    });

    document.getElementById('modal-install-btn').addEventListener('click', async () => {
      const extensionId = document.getElementById('extension-id-input').value.trim();
      if (extensionId && window.nexusAPI) {
        const result = await window.nexusAPI.extensions.installFromWebStore(extensionId);
        if (result) {
          this.loadExtensions();
        }
        document.getElementById('extension-modal').classList.add('hidden');
        document.getElementById('extension-id-input').value = '';
      }
    });

    document.getElementById('load-unpacked-btn').addEventListener('click', async () => {
      if (window.nexusAPI) {
        const result = await window.nexusAPI.extensions.loadUnpacked();
        if (result) {
          this.loadExtensions();
        }
      }
    });

    document.getElementById('clear-downloads-btn').addEventListener('click', async () => {
      if (window.nexusAPI) {
        await window.nexusAPI.downloads.clearDownloads();
        this.loadDownloads();
      }
    });

    document.getElementById('export-passwords-btn').addEventListener('click', async () => {
      const masterPassword = prompt('Enter master password to export:');
      if (masterPassword && window.nexusAPI) {
        await window.nexusAPI.passwords.exportPasswords(masterPassword);
      }
    });

    document.getElementById('import-passwords-btn').addEventListener('click', async () => {
      const masterPassword = prompt('Enter master password to import:');
      if (masterPassword && window.nexusAPI) {
        const result = await window.nexusAPI.passwords.importPasswords('', masterPassword);
        if (result) {
          this.loadPasswords();
        }
      }
    });

    document.getElementById('privacy-toggle-input').addEventListener('change', async (e) => {
      if (window.nexusAPI) {
        await window.nexusAPI.privacy.toggle(e.target.checked);
        this.updatePrivacyIndicator(e.target.checked);
      }
    });

    document.getElementById('add-domain-btn').addEventListener('click', async () => {
      const input = document.getElementById('new-domain');
      const domain = input.value.trim();
      if (domain && window.nexusAPI) {
        const domains = await window.nexusAPI.privacy.addBlockedDomain(domain);
        this.updateBlockedDomainsList(domains);
        input.value = '';
      }
    });

    document.getElementById('save-settings-btn').addEventListener('click', async () => {
      if (window.nexusAPI) {
        const settings = {
          privacy: {
            blockTrackers: document.getElementById('setting-block-trackers').checked,
            blockAds: document.getElementById('setting-block-ads').checked,
          },
          downloads: {
            askDownloadPath: document.getElementById('setting-ask-download-path').checked,
          },
          reading: {},
        };
        await window.nexusAPI.settings.saveSettings(settings);
      }
    });

    document.getElementById('menu-new-tab').addEventListener('click', () => { this.createTab(); this.closePanels(); });
    document.getElementById('menu-bookmarks').addEventListener('click', () => this.togglePanel('bookmarks'));
    document.getElementById('menu-extensions').addEventListener('click', () => this.togglePanel('extensions'));
    document.getElementById('menu-downloads').addEventListener('click', () => { this.togglePanel('downloads'); this.loadDownloads(); this.closePanels(); });
    document.getElementById('menu-settings').addEventListener('click', () => { this.togglePanel('settings'); this.closePanels(); });
    document.getElementById('menu-zoom-in').addEventListener('click', () => { this.zoomIn(); this.closePanels(); });
    document.getElementById('menu-zoom-out').addEventListener('click', () => { this.zoomOut(); this.closePanels(); });
    document.getElementById('menu-reset-zoom').addEventListener('click', () => { this.resetZoom(); this.closePanels(); });
    document.getElementById('menu-about').addEventListener('click', () => { this.showAbout(); this.closePanels(); });
    document.getElementById('menu-new-window').addEventListener('click', () => {
      if (window.nexusAPI) window.nexusAPI.newWindow();
      this.closePanels();
    });
    document.getElementById('menu-history').addEventListener('click', () => this.closePanels());

    document.addEventListener('click', (e) => {
      if (!this.menuPanel.contains(e.target) && e.target.id !== 'menu-btn') {
        this.menuPanel.classList.add('hidden');
      }
    });

    if (window.nexusAPI) {
      window.nexusAPI.onNavigate((url) => this.navigate(url));
      window.nexusAPI.onNewTab(() => this.createTab());

      document.getElementById('minimize-btn').addEventListener('click', () => {
        window.nexusAPI.windowControls.minimize();
      });
      document.getElementById('maximize-btn').addEventListener('click', () => {
        window.nexusAPI.windowControls.maximize();
      });
      document.getElementById('close-btn').addEventListener('click', () => {
        window.nexusAPI.windowControls.close();
      });
    }

    document.addEventListener('keydown', (e) => {
      if (e.ctrlKey || e.metaKey) {
        switch (e.key) {
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
            this.urlInput.focus();
            break;
          case 'r':
            e.preventDefault();
            this.refresh();
            break;
          case '=':
          case '+':
            e.preventDefault();
            this.zoomIn();
            break;
          case '-':
            e.preventDefault();
            this.zoomOut();
            break;
          case '0':
            e.preventDefault();
            this.resetZoom();
            break;
          case 'd':
            e.preventDefault();
            this.toggleBookmark();
            break;
        }
      }
    });
  }

  loadQuickLinks() {
    this.quickLinksContainer.innerHTML = QUICK_LINKS.map(link => `
      <a href="#" class="quick-link" data-url="${link.url}">
        <div class="quick-link-icon">${link.icon}</div>
        <span class="quick-link-title">${link.title}</span>
      </a>
    `).join('');

    this.quickLinksContainer.querySelectorAll('.quick-link').forEach(el => {
      el.addEventListener('click', (e) => {
        e.preventDefault();
        this.navigate(el.dataset.url);
      });
    });
  }

  createTab(url = DEFAULT_HOME_PAGE) {
    const tabId = ++this.tabCounter;
    const tab = {
      id: tabId,
      url: url,
      title: url === DEFAULT_HOME_PAGE ? 'New Tab' : url,
      favicon: null,
      loading: false,
    };

    this.tabs.push(tab);

    const tabEl = document.createElement('button');
    tabEl.className = 'tab';
    tabEl.dataset.tabId = tabId;
    tabEl.innerHTML = `
      <span class="tab-title">${tab.title}</span>
      <button class="tab-close" title="Close tab">&times;</button>
    `;

    tabEl.addEventListener('click', (e) => {
      if (!e.target.classList.contains('tab-close')) {
        this.switchTab(tabId);
      }
    });

    tabEl.querySelector('.tab-close').addEventListener('click', (e) => {
      e.stopPropagation();
      this.closeTab(tabId);
    });

    this.tabsContainer.appendChild(tabEl);
    this.switchTab(tabId);

    if (url !== DEFAULT_HOME_PAGE) {
      this.loadUrlInTab(tabId, url);
    }

    return tabId;
  }

  switchTab(tabId) {
    this.activeTabId = tabId;

    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    const tabEl = document.querySelector(`.tab[data-tab-id="${tabId}"]`);
    if (tabEl) tabEl.classList.add('active');

    const tab = this.tabs.find(t => t.id === tabId);
    if (tab) {
      this.urlInput.value = tab.url === DEFAULT_HOME_PAGE ? '' : tab.url;
      this.updateSecurityIcon(tab.url);
      this.updateBookmarkDisplay();
    }

    this.showHome(tab?.url === DEFAULT_HOME_PAGE);
  }

  closeTab(tabId) {
    const index = this.tabs.findIndex(t => t.id === tabId);
    if (index === -1) return;

    this.tabs.splice(index, 1);

    const tabEl = document.querySelector(`.tab[data-tab-id="${tabId}"]`);
    if (tabEl) tabEl.remove();

    const webview = document.querySelector(`webview[data-tab-id="${tabId}"]`);
    if (webview) webview.remove();

    if (this.activeTabId === tabId) {
      if (this.tabs.length > 0) {
        const newIndex = Math.min(index, this.tabs.length - 1);
        this.switchTab(this.tabs[newIndex].id);
      } else {
        this.createTab();
      }
    }
  }

  navigate(input) {
    let url = input.trim();

    if (!url) return;

    if (url.startsWith('nexus://')) {
      if (url === 'nexus://home') {
        this.goHome();
      }
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.includes('.') && !url.includes(' ')) {
        url = 'https://' + url;
      } else {
        url = SEARCH_ENGINE_URL + encodeURIComponent(url);
      }
    }

    this.loadUrlInTab(this.activeTabId, url);
  }

  loadUrlInTab(tabId, url) {
    const tab = this.tabs.find(t => t.id === tabId);
    if (!tab) return;

    tab.url = url;
    tab.loading = true;

    this.urlInput.value = url;
    this.updateSecurityIcon(url);
    this.showHome(false);
    this.showLoading(true);

    let webview = document.querySelector(`webview[data-tab-id="${tabId}"]`);

    if (!webview) {
      webview = document.createElement('webview');
      webview.dataset.tabId = tabId;
      webview.setAttribute('nodeintegration', 'false');
      webview.setAttribute('webpreferences', 'contextIsolation=true');
      webview.setAttribute('allowpopups', 'true');
      webview.setAttribute('plugins', 'true');
      webview.setAttribute('partition', 'persist:nexus');
      this.webviewContainer.appendChild(webview);
      this.webviewContainer.style.display = 'block';

      this.setupWebviewEvents(webview, tabId);
    }

    webview.src = url;
    this.updateTabTitle(tabId, url);
  }

  setupWebviewEvents(webview, tabId) {
    webview.addEventListener('did-start-loading', () => {
      const tab = this.tabs.find(t => t.id === tabId);
      if (tab) tab.loading = true;
      this.showLoading(true);
    });

    webview.addEventListener('did-stop-loading', () => {
      const tab = this.tabs.find(t => t.id === tabId);
      if (tab) tab.loading = false;
      this.showLoading(false);
    });

    webview.addEventListener('did-navigate', (e) => {
      this.updateTabUrl(tabId, e.url);
    });

    webview.addEventListener('did-navigate-in-page', (e) => {
      this.updateTabUrl(tabId, e.url);
    });

    webview.addEventListener('page-title-updated', (e) => {
      this.updateTabTitle(tabId, null, e.title);
    });

    webview.addEventListener('page-favicon-updated', (e) => {
      const tab = this.tabs.find(t => t.id === tabId);
      if (tab && e.favicons.length > 0) {
        tab.favicon = e.favicons[0];
      }
    });

    webview.addEventListener('dom-ready', () => {
      this.applyZoom(webview);
    });

    webview.addEventListener('load-commit', (e) => {
      if (e.isMainFrame) {
        this.updateTabUrl(tabId, e.url);
      }
    });
  }

  updateTabUrl(tabId, url) {
    const tab = this.tabs.find(t => t.id === tabId);
    if (tab) {
      tab.url = url;
      if (this.activeTabId === tabId) {
        this.urlInput.value = url;
        this.updateSecurityIcon(url);
        this.updateBookmarkDisplay();
      }
    }
  }

  updateTabTitle(tabId, url, title) {
    const tab = this.tabs.find(t => t.id === tabId);
    if (tab) {
      tab.title = title || (url ? new URL(url).hostname : 'New Tab');
      const tabEl = document.querySelector(`.tab[data-tab-id="${tabId}"] .tab-title`);
      if (tabEl) tabEl.textContent = tab.title;
    }
  }

  updateSecurityIcon(url) {
    if (!url || url === DEFAULT_HOME_PAGE) {
      this.securityIcon.textContent = '\uD83D\uDCDD';
    } else if (url.startsWith('https://')) {
      this.securityIcon.textContent = '\uD83D\uDD12';
    } else if (url.startsWith('http://')) {
      this.securityIcon.textContent = '\u26A0\uFE0F';
    } else {
      this.securityIcon.textContent = '\uD83D\uDCDD';
    }
  }

  showHome(show) {
    this.homePage.style.display = show ? 'flex' : 'none';
    this.webviewContainer.style.display = show ? 'none' : 'block';
  }

  showLoading(show) {
    const indicator = document.getElementById('loading-indicator');
    if (indicator) {
      indicator.classList.toggle('hidden', !show);
    }
  }

  goBack() {
    const webview = this.getActiveWebview();
    if (webview && webview.canGoBack()) {
      webview.goBack();
    }
  }

  goForward() {
    const webview = this.getActiveWebview();
    if (webview && webview.canGoForward()) {
      webview.goForward();
    }
  }

  refresh() {
    const webview = this.getActiveWebview();
    if (webview) {
      webview.reload();
    }
  }

  goHome() {
    const tab = this.tabs.find(t => t.id === this.activeTabId);
    if (tab) {
      tab.url = DEFAULT_HOME_PAGE;
      tab.title = 'New Tab';
      this.urlInput.value = '';
      this.updateTabTitle(tab.id, null, 'New Tab');
      this.updateSecurityIcon(DEFAULT_HOME_PAGE);
      this.updateBookmarkDisplay();
      this.showHome(true);
    }
  }

  getActiveWebview() {
    return document.querySelector(`webview[data-tab-id="${this.activeTabId}"]`);
  }

  toggleBookmark() {
    const tab = this.tabs.find(t => t.id === this.activeTabId);
    if (!tab || tab.url === DEFAULT_HOME_PAGE) return;

    const index = this.bookmarks.findIndex(b => b.url === tab.url);

    if (index === -1) {
      this.bookmarks.push({ url: tab.url, title: tab.title, date: Date.now() });
      this.starBtn.classList.add('active');
      this.starBtn.textContent = '\u2605';
    } else {
      this.bookmarks.splice(index, 1);
      this.starBtn.classList.remove('active');
      this.starBtn.textContent = '\u2606';
    }

    localStorage.setItem('nexus_bookmarks', JSON.stringify(this.bookmarks));
    this.updateBookmarksList();
  }

  updateBookmarkDisplay() {
    const tab = this.tabs.find(t => t.id === this.activeTabId);
    if (!tab) return;

    const isBookmarked = this.bookmarks.some(b => b.url === tab.url);
    this.starBtn.classList.toggle('active', isBookmarked);
    this.starBtn.textContent = isBookmarked ? '\u2605' : '\u2606';
  }

  togglePanel(panel) {
    const panelMap = {
      extensions: this.extensionsPanel,
      bookmarks: this.bookmarksPanel,
      menu: this.menuPanel,
      privacy: this.privacyPanel,
      downloads: this.downloadsPanel,
      passwords: this.passwordsPanel,
      settings: this.settingsPanel,
      reading: this.readingPanel,
    };

    const targetPanel = panelMap[panel];
    if (!targetPanel) return;

    const wasVisible = !targetPanel.classList.contains('hidden');
    this.closePanels();

    if (!wasVisible) {
      targetPanel.classList.remove('hidden');
      if (panel === 'extensions') this.loadExtensions();
      if (panel === 'bookmarks') this.updateBookmarksList();
      if (panel === 'privacy') this.loadPrivacyStats();
    }
  }

  closePanels() {
    this.extensionsPanel.classList.add('hidden');
    this.bookmarksPanel.classList.add('hidden');
    this.menuPanel.classList.add('hidden');
    this.privacyPanel.classList.add('hidden');
    this.downloadsPanel.classList.add('hidden');
    this.passwordsPanel.classList.add('hidden');
    this.settingsPanel.classList.add('hidden');
    this.readingPanel.classList.add('hidden');
  }

  async loadExtensions() {
    if (!window.nexusAPI) return;

    try {
      const extensions = await window.nexusAPI.getExtensions();
      this.installedExtensions.innerHTML = extensions.length > 0
        ? extensions.map(ext => `
          <div class="extension-item">
            <div class="extension-icon">${ext.icon || '\uD83E\uDDE9'}</div>
            <div class="extension-info">
              <div class="extension-name">${ext.name}</div>
              <div class="extension-version">v${ext.version}</div>
            </div>
            <label class="extension-toggle">
              <input type="checkbox" ${ext.enabled ? 'checked' : ''} onchange="window.browser.toggleExtension('${ext.id}', this.checked)">
              <span class="slider"></span>
            </label>
            <button class="extension-remove" data-ext-id="${ext.id}" title="Remove">&times;</button>
          </div>
        `).join('')
        : '<p style="color: var(--text-secondary); text-align: center; padding: 20px;">No extensions installed</p>';

      this.installedExtensions.querySelectorAll('.extension-remove').forEach(btn => {
        btn.addEventListener('click', async () => {
          await window.nexusAPI.removeExtension(btn.dataset.extId);
          this.loadExtensions();
        });
      });
    } catch (error) {
      console.error('Failed to load extensions:', error);
    }
  }

  async toggleExtension(id, enabled) {
    if (window.nexusAPI) {
      await window.nexusAPI.extensions.toggleExtension(id, enabled);
    }
  }

  async loadPrivacyStats() {
    if (!window.nexusAPI) return;

    try {
      const stats = await window.nexusAPI.privacy.getStats();
      document.getElementById('blocked-count').textContent = stats.blockedCount || stats.blockedTrackers || 0;
      document.getElementById('ads-blocked-count').textContent = stats.blockedAds || 0;

      const domains = await window.nexusAPI.privacy.getBlockedDomains();
      this.updateBlockedDomainsList(domains);
    } catch (error) {
      console.error('Failed to load privacy stats:', error);
    }
  }

  updateBlockedDomainsList(domains) {
    const list = document.getElementById('blocked-domains-list');
    list.innerHTML = '';
    const displayDomains = domains.slice(0, 20);
    displayDomains.forEach(domain => {
      const li = document.createElement('li');
      li.innerHTML = `
        <span>${domain}</span>
        <button data-domain="${domain}">&times;</button>
      `;
      li.querySelector('button').addEventListener('click', async () => {
        const updatedDomains = await window.nexusAPI.privacy.removeBlockedDomain(domain);
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
    if (!window.nexusAPI) return;

    try {
      const downloads = await window.nexusAPI.downloads.getDownloads();
      const list = document.getElementById('downloads-list');
      list.innerHTML = '';

      downloads.slice(0, 20).forEach(download => {
        const item = document.createElement('div');
        item.className = 'download-item';
        item.innerHTML = `
          <div class="name">${download.filename}</div>
          <div class="download-progress">
            <div class="download-progress-bar" style="width: ${download.progress}%"></div>
          </div>
          <div class="download-actions">
            ${download.state === 'downloading' ? `
              <button onclick="window.browser.pauseDownload('${download.id}')">Pause</button>
              <button onclick="window.browser.cancelDownload('${download.id}')">Cancel</button>
            ` : download.state === 'paused' ? `
              <button onclick="window.browser.resumeDownload('${download.id}')">Resume</button>
            ` : download.state === 'completed' ? `
              <button onclick="window.browser.openDownload('${download.id}')">Open</button>
            ` : ''}
          </div>
        `;
        list.appendChild(item);
      });
    } catch (error) {
      console.error('Failed to load downloads:', error);
    }
  }

  async pauseDownload(id) {
    if (window.nexusAPI) {
      await window.nexusAPI.downloads.pauseDownload(id);
      this.loadDownloads();
    }
  }

  async resumeDownload(id) {
    if (window.nexusAPI) {
      await window.nexusAPI.downloads.resumeDownload(id);
      this.loadDownloads();
    }
  }

  async cancelDownload(id) {
    if (window.nexusAPI) {
      await window.nexusAPI.downloads.cancelDownload(id);
      this.loadDownloads();
    }
  }

  async openDownload(id) {
    if (window.nexusAPI) {
      await window.nexusAPI.downloads.openDownload(id);
    }
  }

  async loadPasswords() {
    if (!window.nexusAPI) return;

    try {
      const passwords = await window.nexusAPI.passwords.getPasswords();
      const list = document.getElementById('passwords-list');
      list.innerHTML = '';

      passwords.forEach(pwd => {
        const item = document.createElement('div');
        item.className = 'password-item';
        item.innerHTML = `
          <div class="password-icon">\uD83D\uDD12</div>
          <div class="password-info">
            <div class="site">${pwd.site}</div>
            <div class="username">${pwd.username}</div>
          </div>
          <button class="password-delete" onclick="window.browser.deletePassword('${pwd.id}')">&times;</button>
        `;
        list.appendChild(item);
      });
    } catch (error) {
      console.error('Failed to load passwords:', error);
    }
  }

  async deletePassword(id) {
    if (window.nexusAPI) {
      await window.nexusAPI.passwords.deletePassword(id);
      this.loadPasswords();
    }
  }

  updateBookmarksList() {
    this.bookmarksList.innerHTML = this.bookmarks.length > 0
      ? this.bookmarks.map((b, i) => `
        <div class="bookmark-item">
          <div class="bookmark-icon">\uD83D\uDD16</div>
          <div class="bookmark-info">
            <div class="bookmark-title">${b.title}</div>
            <div class="bookmark-url">${b.url}</div>
          </div>
          <button class="bookmark-remove" data-index="${i}" title="Remove">&times;</button>
        </div>
      `).join('')
      : '<p style="color: var(--text-secondary); text-align: center; padding: 20px;">No bookmarks yet</p>';

    this.bookmarksList.querySelectorAll('.bookmark-item').forEach(el => {
      el.addEventListener('click', (e) => {
        if (!e.target.classList.contains('bookmark-remove')) {
          const url = el.querySelector('.bookmark-url').textContent;
          this.navigate(url);
          this.closePanels();
        }
      });
    });

    this.bookmarksList.querySelectorAll('.bookmark-remove').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.bookmarks.splice(parseInt(btn.dataset.index), 1);
        localStorage.setItem('nexus_bookmarks', JSON.stringify(this.bookmarks));
        this.updateBookmarksList();
        this.updateBookmarkDisplay();
      });
    });
  }

  zoomIn() {
    this.zoomLevel = Math.min(this.zoomLevel + 0.1, 3.0);
    this.applyZoomToAll();
    this.updateZoomDisplay();
  }

  zoomOut() {
    this.zoomLevel = Math.max(this.zoomLevel - 0.1, 0.25);
    this.applyZoomToAll();
    this.updateZoomDisplay();
  }

  resetZoom() {
    this.zoomLevel = 1.0;
    this.applyZoomToAll();
    this.updateZoomDisplay();
  }

  applyZoomToAll() {
    document.querySelectorAll('webview').forEach(webview => {
      this.applyZoom(webview);
    });
  }

  applyZoom(webview) {
    if (webview && webview.getZoomFactor) {
      webview.setZoomFactor(this.zoomLevel);
    }
  }

  updateZoomDisplay() {
    this.zoomDisplay.textContent = Math.round(this.zoomLevel * 100) + '%';
  }

  async showAbout() {
    const version = window.nexusAPI ? await window.nexusAPI.getAppVersion() : '1.0.0';
    alert(`Nexus Browser\nVersion ${version}\n\nA next-generation browser with full Chrome Web Store support.`);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  window.browser = new NexusBrowser();
});
