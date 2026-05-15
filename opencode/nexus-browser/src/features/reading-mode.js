class ReadingMode {
  constructor(mainWindow) {
    this.mainWindow = mainWindow;
    this.settingsPath = require('path').join(require('electron').app.getPath('userData'), 'reading-settings.json');

    this.settings = {
      theme: 'light',
      fontSize: 16,
      fontFamily: 'Georgia, serif'
    };

    this.loadSettings();
  }

  loadSettings() {
    const fs = require('fs');
    try {
      if (fs.existsSync(this.settingsPath)) {
        this.settings = { ...this.settings, ...JSON.parse(fs.readFileSync(this.settingsPath, 'utf8')) };
      }
    } catch (err) {
      console.error('Failed to load reading settings:', err);
    }
  }

  saveSettings(additionalSettings = {}) {
    const fs = require('fs');
    this.settings = { ...this.settings, ...additionalSettings };
    try {
      fs.writeFileSync(this.settingsPath, JSON.stringify(this.settings, null, 2));
    } catch (err) {
      console.error('Failed to save reading settings:', err);
    }
  }

  extractArticle(html) {
    try {
      const jsdom = require('jsdom');
      const { JSDOM } = jsdom;
      const dom = new JSDOM(html);
      const doc = dom.window.document;

      const article = this.findArticleContent(doc);

      if (article) {
        return {
          title: this.extractTitle(doc),
          content: this.cleanContent(article),
          author: this.extractAuthor(doc),
          publishDate: this.extractDate(doc)
        };
      }

      return null;
    } catch (err) {
      console.error('Failed to extract article:', err);
      return this.fallbackExtract(html);
    }
  }

  findArticleContent(doc) {
    const selectors = [
      'article',
      '[role="article"]',
      '.article',
      '.post',
      '.entry',
      '.content',
      '#content',
      '.story-body',
      '.article-body',
      '.post-content',
      '.entry-content',
      'main',
      '[role="main"]'
    ];

    for (const selector of selectors) {
      const element = doc.querySelector(selector);
      if (element && element.textContent.length > 200) {
        return element;
      }
    }

    return this.findLargestTextBlock(doc);
  }

  findLargestTextBlock(doc) {
    const paragraphs = doc.querySelectorAll('p');
    if (paragraphs.length === 0) return null;

    let bestElement = null;
    let maxTextLength = 0;

    const containers = doc.querySelectorAll('div, section, article');
    containers.forEach(container => {
      const textLength = container.textContent.length;
      if (textLength > maxTextLength && textLength > 500) {
        maxTextLength = textLength;
        bestElement = container;
      }
    });

    return bestElement;
  }

  extractTitle(doc) {
    const ogTitle = doc.querySelector('meta[property="og:title"]');
    if (ogTitle) return ogTitle.getAttribute('content');

    const title = doc.querySelector('title');
    if (title) return title.textContent;

    const h1 = doc.querySelector('h1');
    if (h1) return h1.textContent;

    return '';
  }

  extractAuthor(doc) {
    const authorMeta = doc.querySelector('meta[name="author"]');
    if (authorMeta) return authorMeta.getAttribute('content');

    const authorElement = doc.querySelector('[rel="author"], .author, .byline');
    if (authorElement) return authorElement.textContent.trim();

    return '';
  }

  extractDate(doc) {
    const dateMeta = doc.querySelector('meta[property="article:published_time"], meta[name="date"]');
    if (dateMeta) return dateMeta.getAttribute('content');

    const timeElement = doc.querySelector('time');
    if (timeElement) return timeElement.getAttribute('datetime') || timeElement.textContent;

    return '';
  }

  cleanContent(element) {
    const clone = element.cloneNode(true);

    const removeSelectors = [
      'script',
      'style',
      'nav',
      'header',
      'footer',
      '.sidebar',
      '.comments',
      '.related',
      '.share',
      '.ad',
      '.advertisement',
      '[class*="ad-"]',
      '[id*="ad-"]',
      'iframe',
      '.social',
      '.navigation'
    ];

    removeSelectors.forEach(selector => {
      clone.querySelectorAll(selector).forEach(el => el.remove());
    });

    return clone.innerHTML;
  }

  fallbackExtract(html) {
    const titleMatch = html.match(/<title>(.*?)<\/title>/i);
    const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);

    if (bodyMatch) {
      const textContent = bodyMatch[1].replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
      return {
        title: titleMatch ? titleMatch[1] : 'Article',
        content: `<p>${textContent.substring(0, 5000)}</p>`,
        author: '',
        publishDate: ''
      };
    }

    return null;
  }

  getSettings() {
    return this.settings;
  }

  saveSettings(settings) {
    this.saveSettings(settings);
  }
}

module.exports = ReadingMode;
