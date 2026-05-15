const READING_MODE_CSS = `
  .nexus-reading-mode {
    font-family: 'Georgia', 'Times New Roman', serif !important;
    line-height: 1.8 !important;
    max-width: 680px !important;
    margin: 0 auto !important;
    padding: 40px 20px !important;
    background: #faf9f6 !important;
    color: #333 !important;
  }

  .nexus-reading-mode * {
    font-family: inherit !important;
    max-width: 100% !important;
  }

  .nexus-reading-mode h1,
  .nexus-reading-mode h2,
  .nexus-reading-mode h3 {
    margin-top: 1.5em !important;
    margin-bottom: 0.5em !important;
    line-height: 1.3 !important;
  }

  .nexus-reading-mode p {
    margin-bottom: 1.2em !important;
    font-size: 18px !important;
  }

  .nexus-reading-mode img {
    max-width: 100% !important;
    height: auto !important;
    display: block !important;
    margin: 1.5em auto !important;
    border-radius: 4px !important;
  }

  .nexus-reading-mode a {
    color: #0066cc !important;
    text-decoration: underline !important;
  }

  .nexus-reading-mode blockquote {
    border-left: 3px solid #ccc !important;
    padding-left: 1em !important;
    margin-left: 0 !important;
    color: #666 !important;
    font-style: italic !important;
  }

  .nexus-reading-mode code {
    background: #f4f4f4 !important;
    padding: 2px 6px !important;
    border-radius: 3px !important;
    font-family: 'Consolas', 'Monaco', monospace !important;
    font-size: 0.9em !important;
  }

  .nexus-reading-mode pre {
    background: #f4f4f4 !important;
    padding: 1em !important;
    border-radius: 4px !important;
    overflow-x: auto !important;
  }

  .nexus-reading-mode-dark {
    background: #1a1a1a !important;
    color: #e0e0e0 !important;
  }

  .nexus-reading-mode-dark a {
    color: #66b3ff !important;
  }

  .nexus-reading-mode-dark blockquote {
    border-left-color: #555 !important;
    color: #aaa !important;
  }

  .nexus-reading-mode-dark code,
  .nexus-reading-mode-dark pre {
    background: #2a2a2a !important;
  }

  .nexus-reading-mode-sepia {
    background: #f4ecd8 !important;
    color: #5b4636 !important;
  }

  .nexus-reading-mode-sepia a {
    color: #8b4513 !important;
  }

  .nexus-reading-toolbar {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    height: 48px !important;
    background: rgba(255, 255, 255, 0.95) !important;
    backdrop-filter: blur(10px) !important;
    display: flex !important;
    align-items: center !important;
    justify-content: space-between !important;
    padding: 0 20px !important;
    z-index: 10000 !important;
    border-bottom: 1px solid #eee !important;
  }

  .nexus-reading-toolbar-dark {
    background: rgba(26, 26, 26, 0.95) !important;
    border-bottom-color: #333 !important;
  }

  .nexus-reading-toolbar button {
    background: none !important;
    border: 1px solid #ddd !important;
    padding: 6px 12px !important;
    border-radius: 4px !important;
    cursor: pointer !important;
    font-size: 14px !important;
    color: inherit !important;
  }

  .nexus-reading-toolbar button:hover {
    background: #f0f0f0 !important;
  }

  .nexus-reading-progress {
    position: fixed !important;
    top: 48px !important;
    left: 0 !important;
    height: 3px !important;
    background: linear-gradient(90deg, #e94560, #ff6b81) !important;
    z-index: 10000 !important;
    transition: width 0.1s !important;
  }
`;

const READING_MODE_SCRIPT = `
  (function() {
    if (document.querySelector('.nexus-reading-mode')) return;

    const article = document.querySelector('article, main, .article, .content, .post, [role="main"]') || document.body;
    const clone = article.cloneNode(true);

    const stylesToRemove = clone.querySelectorAll('style, link[rel="stylesheet"], script, nav, header, footer, aside, .sidebar, .comments, .ad, .advertisement');
    stylesToRemove.forEach(el => el.remove());

    const readingDiv = document.createElement('div');
    readingDiv.className = 'nexus-reading-mode';
    readingDiv.innerHTML = clone.innerHTML;

    const toolbar = document.createElement('div');
    toolbar.className = 'nexus-reading-toolbar';
    toolbar.innerHTML = \`
      <div>
        <button onclick="nexusReadingMode.setFontSize(-2)">A-</button>
        <button onclick="nexusReadingMode.setFontSize(2)">A+</button>
        <button onclick="nexusReadingMode.setTheme('light')">☀️</button>
        <button onclick="nexusReadingMode.setTheme('dark')">🌙</button>
        <button onclick="nexusReadingMode.setTheme('sepia')">📜</button>
      </div>
      <button onclick="nexusReadingMode.exit()">✕ Exit</button>
    \`;

    const progressBar = document.createElement('div');
    progressBar.className = 'nexus-reading-progress';

    document.body.innerHTML = '';
    document.body.appendChild(toolbar);
    document.body.appendChild(progressBar);
    document.body.appendChild(readingDiv);

    window.nexusReadingMode = {
      fontSize: 18,
      theme: 'light',

      setFontSize(delta) {
        this.fontSize = Math.max(14, Math.min(28, this.fontSize + delta));
        readingDiv.querySelectorAll('p, li').forEach(el => {
          el.style.fontSize = this.fontSize + 'px';
        });
      },

      setTheme(theme) {
        this.theme = theme;
        readingDiv.className = 'nexus-reading-mode';
        toolbar.className = 'nexus-reading-toolbar';

        if (theme === 'dark') {
          readingDiv.classList.add('nexus-reading-mode-dark');
          toolbar.classList.add('nexus-reading-toolbar-dark');
        } else if (theme === 'sepia') {
          readingDiv.classList.add('nexus-reading-mode-sepia');
        }
      },

      exit() {
        window.location.reload();
      },

      updateProgress() {
        const scrollTop = window.scrollY;
        const docHeight = document.documentElement.scrollHeight - window.innerHeight;
        const progress = docHeight > 0 ? (scrollTop / docHeight) * 100 : 0;
        progressBar.style.width = progress + '%';
      }
    };

    window.addEventListener('scroll', () => window.nexusReadingMode.updateProgress());
    window.nexusReadingMode.updateProgress();
  })();
`;

class ReadingMode {
  constructor() {
    this.active = false;
  }

  async activate(webContents) {
    try {
      await webContents.insertCSS(READING_MODE_CSS);
      await webContents.executeJavaScript(READING_MODE_SCRIPT);
      this.active = true;
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async deactivate(webContents) {
    try {
      await webContents.executeJavaScript('window.nexusReadingMode?.exit()');
      this.active = false;
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  isActive() {
    return this.active;
  }
}

module.exports = ReadingMode;
