const DEFAULT_HOME_PAGE = 'nexus://home';
const SEARCH_ENGINE_URL = 'https://www.google.com/search?q=';

const QUICK_LINKS = [
  { title: 'Google', url: 'https://google.com', icon: '🔍' },
  { title: 'YouTube', url: 'https://youtube.com', icon: '▶️' },
  { title: 'GitHub', url: 'https://github.com', icon: '🐙' },
  { title: 'Reddit', url: 'https://reddit.com', icon: '🤖' },
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
  }

  cacheElements() {
    this.urlInput = document.getElementById('url-input');
    this.homeSearch = document.getElementById('home-search');
    this.tabsContainer = document.getElementById('tabs');
    this.webviewContainer = document.getElementById('webview-container');
    this.homePage = document.getElementById('home-page');
    this.statusText = document.getElementById('status-text');
    this.zoomDisplay = document.getElementById('zoom-level');
    this.securityIcon = document.getElementById('security-icon');
    this.extensionsPanel = document.getElementById('extensions-panel');
    this.bookmarksPanel = document.getElementById('bookmarks-panel');
    this.menuPanel = document.getElementById('menu-panel');
    this.installedExtensions = document.getElementById('installed-extensions');
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
    document.getElementById('star-btn').addEventListener('click', () => this.toggleBookmark());

    document.getElementById('extensions-btn').addEventListener('click', () => this.togglePanel('extensions'));
    document.getElementById('menu-btn').addEventListener('click', () => this.togglePanel('menu'));
    document.getElementById('close-extensions').addEventListener('click', () => this.closePanels());
    document.getElementById('close-bookmarks').addEventListener('click', () => this.closePanels());

    document.getElementById('install-extension-btn').addEventListener('click', () => this.installExtension());

    document.getElementById('menu-new-tab').addEventListener('click', () => { this.createTab(); this.closePanels(); });
    document.getElementById('menu-bookmarks').addEventListener('click', () => this.togglePanel('bookmarks'));
    document.getElementById('menu-extensions').addEventListener('click', () => this.togglePanel('extensions'));
    document.getElementById('menu-zoom-in').addEventListener('click', () => { this.zoomIn(); this.closePanels(); });
    document.getElementById('menu-zoom-out').addEventListener('click', () => { this.zoomOut(); this.closePanels(); });
    document.getElementById('menu-reset-zoom').addEventListener('click', () => { this.resetZoom(); this.closePanels(); });
    document.getElementById('menu-about').addEventListener('click', () => { this.showAbout(); this.closePanels(); });

    document.addEventListener('click', (e) => {
      if (!this.menuPanel.contains(e.target) && e.target.id !== 'menu-btn') {
        this.menuPanel.classList.add('hidden');
      }
    });

    if (window.nexusAPI) {
      window.nexusAPI.onNavigate((url) => this.navigate(url));
      window.nexusAPI.onNewTab(() => this.createTab());
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
      <button class="tab-close" title="Close tab">×</button>
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

    let webview = document.querySelector(`webview[data-tab-id="${tabId}"]`);

    if (!webview) {
      webview = document.createElement('webview');
      webview.dataset.tabId = tabId;
      webview.setAttribute('nodeintegration', 'false');
      webview.setAttribute('webpreferences', 'contextIsolation=true');
      webview.setAttribute('allowpopups', 'true');
      webview.setAttribute('plugins', 'true');
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
    });

    webview.addEventListener('did-stop-loading', () => {
      const tab = this.tabs.find(t => t.id === tabId);
      if (tab) tab.loading = false;
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
    if (url.startsWith('https://')) {
      this.securityIcon.textContent = '🔒';
    } else if (url.startsWith('http://')) {
      this.securityIcon.textContent = '⚠️';
    } else {
      this.securityIcon.textContent = '📄';
    }
  }

  showHome(show) {
    this.homePage.style.display = show ? 'flex' : 'none';
    this.webviewContainer.style.display = show ? 'none' : 'block';
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
    const starBtn = document.getElementById('star-btn');

    if (index === -1) {
      this.bookmarks.push({ url: tab.url, title: tab.title, date: Date.now() });
      starBtn.classList.add('active');
      starBtn.textContent = '★';
    } else {
      this.bookmarks.splice(index, 1);
      starBtn.classList.remove('active');
      starBtn.textContent = '☆';
    }

    localStorage.setItem('nexus_bookmarks', JSON.stringify(this.bookmarks));
    this.updateBookmarkDisplay();
  }

  updateBookmarkDisplay() {
    const tab = this.tabs.find(t => t.id === this.activeTabId);
    if (!tab) return;

    const isBookmarked = this.bookmarks.some(b => b.url === tab.url);
    const starBtn = document.getElementById('star-btn');
    starBtn.classList.toggle('active', isBookmarked);
    starBtn.textContent = isBookmarked ? '★' : '☆';
  }

  togglePanel(panel) {
    const wasVisible = !this[`${panel}Panel`].classList.contains('hidden');
    this.closePanels();

    if (!wasVisible) {
      this[`${panel}Panel`].classList.remove('hidden');
      if (panel === 'extensions') this.loadExtensions();
      if (panel === 'bookmarks') this.updateBookmarksList();
    }
  }

  closePanels() {
    this.extensionsPanel.classList.add('hidden');
    this.bookmarksPanel.classList.add('hidden');
    this.menuPanel.classList.add('hidden');
  }

  async loadExtensions() {
    if (!window.nexusAPI) return;

    try {
      const extensions = await window.nexusAPI.getExtensions();
      this.installedExtensions.innerHTML = extensions.length > 0
        ? extensions.map(ext => `
          <div class="extension-item">
            <div class="extension-icon">🧩</div>
            <div class="extension-info">
              <div class="extension-name">${ext.name}</div>
              <div class="extension-version">v${ext.version}</div>
            </div>
            <button class="extension-remove" data-ext-id="${ext.id}" title="Remove">×</button>
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

  async installExtension() {
    if (!window.nexusAPI) return;

    try {
      const result = await window.nexusAPI.openDialog({
        properties: ['openDirectory'],
        title: 'Select Extension Folder',
      });

      if (!result.canceled && result.filePaths.length > 0) {
        const installResult = await window.nexusAPI.installExtension(result.filePaths[0]);
        if (installResult.success) {
          this.loadExtensions();
        } else {
          alert('Failed to install extension: ' + installResult.error);
        }
      }
    } catch (error) {
      console.error('Failed to install extension:', error);
    }
  }

  updateBookmarksList() {
    this.bookmarksList.innerHTML = this.bookmarks.length > 0
      ? this.bookmarks.map((b, i) => `
        <div class="bookmark-item">
          <div class="bookmark-icon">🔖</div>
          <div class="bookmark-info">
            <div class="bookmark-title">${b.title}</div>
            <div class="bookmark-url">${b.url}</div>
          </div>
          <button class="bookmark-remove" data-index="${i}" title="Remove">×</button>
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
    const version = window.nexusAPI ? await window.nexusAPI.getAppVersion() : '0.1.0';
    alert(`Nexus Browser\nVersion ${version}\n\nA next-generation browser with full Chrome Web Store support.`);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  window.browser = new NexusBrowser();
});
