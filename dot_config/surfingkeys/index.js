// =============================================================================
// Surfingkeys Configuration
// =============================================================================

// -- Settings --
settings.omnibarHistoryCacheSize = 500;
settings.modeAfterYank = 'Normal';
settings.scrollStepSize = 100;
settings.prevLinkRegex = /((<<|prev(ious)?)|<|‹|«|←|前[のへ]+)/i;
settings.nextLinkRegex = /((>>|next)|>|›|»|→|次[のへ]+)/i;
settings.hintAlign = 'left';
settings.hintShiftNonActive = true;
settings.blocklistPattern = /mail\.google\.com/i;
settings.tabsMRUOrder = false;
settings.historyMUOrder = false;
settings.cursorAtEndOfInput = false;
// Show LLM/AI chat via built-in `A` if you configure settings.llm
// settings.defaultLLMProvider = 'ollama';

api.Hints.setCharacters('asdfwerxcvuionm');

// -- Utilities --
const unmapKeys   = (keys) => keys.forEach((key) => api.unmap(key));
const iunmapKeys  = (keys) => keys.forEach((key) => api.iunmap(key));

const escapeMap = {
  '&': '&amp;', '<': '&lt;', '>': '&gt;',
  '"': '&quot;', "'": '&#39;', '/': '&#x2F;',
  '`': '&#x60;', '=': '&#x3D;',
};
const escapeForAlias = (str) =>
  String(str).replace(/[&<>"'`=/]/g, (s) => escapeMap[s]);

const createSuggestionItem = (html, props = {}) => {
  const li = document.createElement('li');
  li.innerHTML = html;
  return { html: li.outerHTML, props };
};

const padZero = (txt) => `0${txt}`.slice(-2);
const formatDate = (date, format = 'YYYY/MM/DD hh:mm:ss') =>
  format
    .replace('YYYY', date.getFullYear())
    .replace('MM',   padZero(date.getMonth() + 1))
    .replace('DD',   padZero(date.getDate()))
    .replace('hh',   padZero(date.getHours()))
    .replace('mm',   padZero(date.getMinutes()))
    .replace('ss',   padZero(date.getSeconds()));

const tabOpenBackground = (url) =>
  api.RUNTIME('openLink', { tab: { tabbed: true, active: false }, url });

// Copy page title + URL in various formats
const copyTitleAndUrl = (format) => {
  const text = format
    .replace('%TITLE%', document.title)
    .replace('%URL%',   location.href);        // FIX: original was missing %URL% replacement
  api.Clipboard.write(text);
};

// Copy as rich HTML link (paste into Gmail, Notion, etc.)
const copyHtmlLink = async () => {
  const title = document.title;
  const url   = location.href;
  const html  = `<a href="${url}">${escapeForAlias(title)}</a>`;  // FIX: escape title in HTML
  const plain = `${title} - ${url}`;
  try {
    await navigator.clipboard.write([
      new ClipboardItem({
        'text/html':  new Blob([html],  { type: 'text/html' }),
        'text/plain': new Blob([plain], { type: 'text/plain' }),
      }),
    ]);
    api.Front.showBanner('Rich Copied: ' + title);
  } catch (err) {
    console.error('Copy failed', err);
    api.Front.showBanner('Copy failed: ' + err.message);
  }
};

// =============================================================================
// Inline Readability — strips boilerplate, extracts article body
// Source: https://github.com/mozilla/readability (Apache-2.0)
// Paste the minified build here so CSP cannot block it.
// To update: https://unpkg.com/@mozilla/readability/Readability.js → minify → paste
// =============================================================================
// PASTE_READABILITY_MIN_JS_HERE
// e.g.: var Readability=function(){"use strict";...}();

// =============================================================================
// Inline Turndown — converts HTML to Markdown
// Source: https://github.com/mixmark-io/turndown (MIT)
// To update: https://unpkg.com/turndown/dist/turndown.js → minify → paste
// =============================================================================
// PASTE_TURNDOWN_MIN_JS_HERE
// e.g.: var TurndownService=function(){"use strict";...}();

// Pure-JS fallback HTML→Markdown converter (no external deps, covers common cases)
// Used automatically when the inlined libraries above are not present.
const htmlToMarkdownFallback = (html) => {
  const el = document.createElement('div');
  el.innerHTML = html;

  const walk = (node, ctx = '') => {
    if (node.nodeType === Node.TEXT_NODE) {
      return node.textContent.replace(/\n{3,}/g, '\n\n');
    }
    if (node.nodeType !== Node.ELEMENT_NODE) return '';

    const tag      = node.tagName.toLowerCase();
    const children = () => Array.from(node.childNodes).map((n) => walk(n, ctx)).join('');

    // Block elements
    if (['script', 'style', 'noscript', 'nav', 'footer', 'aside'].includes(tag)) return '';
    if (tag === 'br')   return '\n';
    if (tag === 'hr')   return '\n---\n';
    if (tag === 'p')    return `\n\n${children()}\n\n`;
    if (tag === 'blockquote') return children().split('\n').map((l) => `> ${l}`).join('\n') + '\n';
    if (/^h([1-6])$/.test(tag)) {
      const level = parseInt(tag[1]);
      return `\n\n${'#'.repeat(level)} ${children()}\n\n`;
    }
    if (tag === 'pre') {
      const code = node.querySelector('code');
      const lang = (code?.className.match(/language-(\S+)/) || [])[1] || '';
      return `\n\n\`\`\`${lang}\n${(code || node).textContent}\n\`\`\`\n\n`;
    }
    if (tag === 'ul') {
      return '\n' + Array.from(node.children).map((li) => `- ${walk(li).trim()}`).join('\n') + '\n';
    }
    if (tag === 'ol') {
      return '\n' + Array.from(node.children).map((li, i) => `${i + 1}. ${walk(li).trim()}`).join('\n') + '\n';
    }
    if (tag === 'li')   return children();
    if (tag === 'table') {
      const rows = Array.from(node.querySelectorAll('tr'));
      if (!rows.length) return '';
      const toRow = (r) => '| ' + Array.from(r.querySelectorAll('th,td')).map((c) => c.textContent.trim()).join(' | ') + ' |';
      const header = toRow(rows[0]);
      const sep    = header.replace(/[^|]/g, '-').replace(/--/g, '--');
      return '\n' + [header, sep, ...rows.slice(1).map(toRow)].join('\n') + '\n';
    }

    // Inline elements
    if (tag === 'code')   return `\`${node.textContent}\``;
    if (tag === 'strong' || tag === 'b') return `**${children()}**`;
    if (tag === 'em'     || tag === 'i') return `*${children()}*`;
    if (tag === 's'      || tag === 'del') return `~~${children()}~~`;
    if (tag === 'a') {
      const href = node.getAttribute('href');
      const text = children().trim();
      if (!href || href.startsWith('javascript:')) return text;
      const abs = href.startsWith('http') ? href : new URL(href, location.href).href;
      return text ? `[${text}](${abs})` : abs;
    }
    if (tag === 'img') {
      const src = node.getAttribute('src') || '';
      const alt = node.getAttribute('alt') || '';
      const abs = src.startsWith('http') ? src : new URL(src, location.href).href;
      return `![${alt}](${abs})`;
    }

    return children();
  };

  return walk(el)
    .replace(/\n{3,}/g, '\n\n')
    .trim();
};

// Copy entire page as Markdown (Readability content extraction + Turndown or fallback converter)
const pageToMarkdown = () => {
  let content, title;

  // Try Readability first (strips nav/sidebars/ads)
  if (typeof Readability !== 'undefined') {
    const docClone = document.cloneNode(true);
    const article  = new Readability(docClone).parse();
    if (article) {
      title   = article.title;
      content = article.content;
    }
  }

  // Fall back to full body if Readability not available or returned null
  if (!content) {
    title   = document.title;
    content = document.body.innerHTML;
  }

  // Convert HTML → Markdown
  let md;
  if (typeof TurndownService !== 'undefined') {
    const td = new TurndownService({ headingStyle: 'atx', codeBlockStyle: 'fenced' });
    md = td.turndown(content);
  } else {
    md = htmlToMarkdownFallback(content);
  }

  const output = `# ${title}\n\n> Source: ${location.href}\n\n${md}`;
  api.Clipboard.write(output);
  api.Front.showBanner(`Copied as Markdown: ${title}`);
};

const googleTranslateTo = (lang = 'ja') => {
  const selection = window.getSelection().toString();
  const baseUrl   = 'https://translate.google.com';
  if (selection === '') {
    api.tabOpenLink(`${baseUrl}/translate?js=n&sl=auto&tl=${lang}&u=${encodeURIComponent(location.href)}`);
  } else {
    api.tabOpenLink(`${baseUrl}/?sl=auto&tl=${lang}&text=${encodeURIComponent(selection)}`);
  }
};

// ---- PassThrough mode ----
api.mapkey('p', '#0Enter ephemeral PassThrough mode (1.5s)', function () {
  api.Normal.passThrough(1500);
});

// =============================================================================
// Site Helpers
// =============================================================================

const clickElm = (selector) => () => document.querySelector(selector)?.click();

const clickInIframe = (iframeSelector, targetSelector) => () => {
  const iframe    = document.querySelector(iframeSelector);
  const iframeDoc = iframe?.contentWindow?.document;
  iframeDoc?.querySelector(targetSelector)?.click();
};

/**
 * Run fn only when the current URL matches pattern.
 * @param {RegExp} pattern
 * @param {function} fn
 */
const siteMapkey = (pattern, fn) => {
  if (pattern.test(location.href)) fn();
};

/**
 * Unmap an array of keys only on matching URLs.
 * @param {RegExp} pattern
 * @param {string[]} keys
 */
const unmapIfMatch = (pattern, keys) => {
  if (pattern.test(location.href)) unmapKeys(keys);
};

// =============================================================================
// Key Remaps
// =============================================================================

api.map('>_r', 'r');
api.map('>_E', 'E');
api.map('>_R', 'R');
api.map('>_S', 'S');
api.map('S',   'sg');  // Search selected text / clipboard via Google
api.map('r',   'gf');  // Reopen current URL in new tab
api.map('H',   '>_S'); // Back in history
api.map('L',   'D');   // Forward in history
api.map('h',   'E');   // Previous tab
api.map('l',   '>_R'); // Next tab
api.map('R',   '>_r'); // Reload page

api.iunmap(':');        // Disable emoji completion

// Disable proxy shortcuts (not used)
unmapKeys(['cp', ';pa', ';pb', ';pc', ';pd', ';ps', ';ap']);

// Restore standard Emacs/readline editing shortcuts in insert mode
iunmapKeys(['<Ctrl-a>', '<Ctrl-e>', '<Ctrl-f>', '<Ctrl-b>', '<Ctrl-k>', '<Ctrl-y>']);

// =============================================================================
// Search Aliases
// =============================================================================

// Remove Baidu
api.removeSearchAlias('b');

// Amazon.co.jp
api.addSearchAlias(
  'aam',
  'Amazon.jp',
  'https://www.amazon.co.jp/s?k=',
  's',
  'https://completion.amazon.co.jp/search/complete?method=completion&search-alias=aps&mkt=6&q=',
  (response) => JSON.parse(response.text)[1]
);

// Google Japan — past 3 months
api.addSearchAlias(
  'a3',
  'Google 3ヶ月以内',
  'https://www.google.co.jp/search?q={0}&tbs=qdr:m3,lr:lang_1ja&lr=lang_ja'
);

// MDN  (FIX: original used undefined `res` variable; fixed to use `response`)
api.addSearchAlias(
  'amdn',
  'MDN',
  'https://developer.mozilla.org/search?q=',
  's',
  'https://developer.mozilla.org/api/v1/search?q=',
  function (response) {
    const res = JSON.parse(response.text);
    return res.documents.map((s) =>
      createSuggestionItem(
        `<div>
          <div class="title"><strong>${escapeForAlias(s.title)}</strong></div>
          <div style="font-size:0.8em"><em>${escapeForAlias(s.slug)}</em></div>
          <div>${escapeForAlias(s.summary)}</div>
        </div>`,
        { url: `https://developer.mozilla.org/${s.locale}/docs/${s.slug}` }
      )
    );
  }
);

// npm
api.addSearchAlias(
  'anpm',
  'npm',
  'https://www.npmjs.com/search?q=',
  's',
  'https://api.npms.io/v2/search/suggestions?size=20&q=',
  (response) =>
    JSON.parse(response.text).map((s) => {
      let flags = '';
      let desc  = s.package.description ? escapeForAlias(s.package.description) : '';
      let stars = '';
      if (s.score?.final) {
        const score = Math.round(Number(s.score.final) * 5);
        stars = '⭐'.repeat(score) + '☆'.repeat(5 - score);
      }
      if (s.flags) {
        Object.keys(s.flags).forEach((f) => {
          flags += `[<span style='color:#ff4d00'>⚑</span> ${escapeForAlias(f)}] `;
        });
      }
      return createSuggestionItem(
        `<div>
          <style>.title>em { font-weight: bold; }</style>
          <div class="title">${s.highlight}</div>
          <div>
            <span style="font-size:1.5em;line-height:1em">${stars}</span>
            <span>${flags}</span>
          </div>
          <div>${desc}</div>
        </div>`,
        { url: s.package.links.npm }
      );
    })
);

// PyPI via Libraries.io
const LIBRARIES_IO_API_KEY = 'YOUR_LIBRARIES_IO_API_KEY'; // replace with your key
api.addSearchAlias(
  'apy',
  'PyPI via Libraries.io',
  'https://pypi.org/project/',
  's',
  `https://libraries.io/api/search?q=&api_key=${LIBRARIES_IO_API_KEY}`,
  (response) =>
    JSON.parse(response.text)
      .filter((r) => r.platform === 'Pypi')
      .slice(0, 10)
      .map((pkg) =>
        createSuggestionItem(
          `<div>
            <div class="title"><strong>${escapeForAlias(pkg.name)}</strong></div>
            <div>${escapeForAlias(pkg.description || '')}</div>
          </div>`,
          { url: `https://pypi.org/project/${pkg.name}/` }
        )
      )
);

// Python Language Reference
api.addSearchAlias('pp', 'Python 言語リファレンス', 'https://docs.python.org/3/search.html?q=');
api.mapkey('opp', 'Search: Python 言語リファレンス', function () {
  api.Front.openOmnibar({ type: 'SearchEngine', extra: 'pp' });
});

// NEW: GitHub Code Search
api.addSearchAlias('agh', 'GitHub Code', 'https://github.com/search?type=code&q=');

// NEW: Homebrew Formulae
api.addSearchAlias('abrew', 'Homebrew', 'https://formulae.brew.sh/formula/');

// =============================================================================
// Copy / Share
// =============================================================================

api.mapkey('cm', '#7Copy as [title](url) Markdown link', () => {
  copyTitleAndUrl('[%TITLE%](%URL%)');
});

// Copy as plain "title - url" text
api.mapkey('ct', '#7Copy as "title - url" plain text', () => {
  copyTitleAndUrl('%TITLE% - %URL%');
});

// Copy rich HTML link (works in Gmail, Notion, etc.)
api.mapkey('ch', '#7Copy as rich HTML <a> link', copyHtmlLink);

// Copy entire page content as Markdown (Readability + Turndown)
api.mapkey('cM', '#7Copy entire page as Markdown', pageToMarkdown);

// =============================================================================
// Translation
// =============================================================================

api.unmap(';t');
api.mapkey(';tj',  '#14Translate to Japanese',  () => googleTranslateTo('ja'));
api.mapkey(';te',  '#14Translate to English',   () => googleTranslateTo('en'));
api.mapkey(';tch', '#14Translate to Chinese',   () => googleTranslateTo('zh-TW'));

// =============================================================================
// Developer tools
// =============================================================================

// Open DeepWiki for current GitHub repo
api.mapkey(';dw', 'deepWiki: Open DeepWiki for this GitHub repo', function () {
  const match = window.location.href.match(/^https:\/\/github\.com\/([^/]+)\/([^/?#]+)/);
  if (match) {
    window.open(`https://deepwiki.com/${match[1]}/${match[2]}`, '_blank');
  } else {
    api.Front.showPopup('deepWiki: Not a valid GitHub repo URL.');
  }
});

// NEW: Open current page in web.archive.org Wayback Machine
api.mapkey(';wb', 'Wayback Machine: open current URL', function () {
  window.open(`https://web.archive.org/web/*/${location.href}`, '_blank');
});

// NEW: Copy current URL as raw text (handy fallback)
api.mapkey('yu', '#7Copy current URL', () => {
  api.Clipboard.write(location.href);
  api.Front.showBanner('Copied URL: ' + location.href);
});

// =============================================================================
// FW / Trotto Go Links
// =============================================================================

api.mapkey(';gol', 'Open a Trotto Go Link', function () {
  const url = window.prompt('Trotto Go Link:');
  if (url && url.trim()) {
    window.location.href = `https://go/${url.trim()}`;
  }
});

// =============================================================================
// Site-Specific Mappings
// =============================================================================

// speakerdeck.com
siteMapkey(/speakerdeck\.com/, () => {
  api.mapkey(']', 'Next slide', clickInIframe('.speakerdeck-iframe', '.sd-player-next'));
  api.mapkey('[', 'Prev slide', clickInIframe('.speakerdeck-iframe', '.sd-player-previous'));
});

// slideshare.net
siteMapkey(/www\.slideshare\.net/, () => {
  api.mapkey(']', 'Next slide', clickElm('#btnNext'));
  api.mapkey('[', 'Prev slide', clickElm('#btnPrevious'));
});

// booklog.jp
siteMapkey(/booklog\.jp/, () => {
  api.mapkey(']', 'Next review page', clickElm('#modal-review-next'));
  api.mapkey('[', 'Prev review page', clickElm('#modal-review-prev'));
  api.mapkey('d', 'Mark as read',     clickElm('#status3'));
  api.mapkey('R', 'Open in Kindle', () => {
    const asin = document
      .querySelector('.item-area-info-title a')
      ?.getAttribute('href')
      ?.replace(/.*\//, '');
    if (asin) {
      api.RUNTIME('openLink', { tab: { tabbed: true }, url: `https://read.amazon.co.jp/?asin=${asin}` });
    }
  });
});

// GitHub
const github_username = 'jack06215';
const github_profile  = ['jack06215', 'flywheel-jp'];

siteMapkey(/github\.com/, () => {
  // Go to assigned PRs for the current repo
  api.mapkey('ga', 'Go to assigned PRs for current GitHub repo', function () {
    const match = window.location.href.match(/^https:\/\/github\.com\/([^/]+)\/([^/?#]+)/);
    if (match && github_profile.includes(match[1])) {
      const [, user, repo] = match;
      window.location.href = `https://github.com/${user}/${repo}/pulls?q=is%3Apr+is%3Aopen+assignee%3A${github_username}`;
    } else {
      api.Front.showPopup('Not a valid GitHub repo URL or unrecognised org.');
    }
  });

  // NEW: Go to review-requested PRs
  api.mapkey('gr', 'Go to PRs requesting my review', function () {
    const match = window.location.href.match(/^https:\/\/github\.com\/([^/]+)\/([^/?#]+)/);
    if (match) {
      const [, user, repo] = match;
      window.location.href = `https://github.com/${user}/${repo}/pulls?q=is%3Apr+is%3Aopen+review-requested%3A${github_username}`;
    }
  });

  // NEW: Go to my open PRs in current repo
  api.mapkey('gm', 'Go to my open PRs in current repo', function () {
    const match = window.location.href.match(/^https:\/\/github\.com\/([^/]+)\/([^/?#]+)/);
    if (match) {
      const [, user, repo] = match;
      window.location.href = `https://github.com/${user}/${repo}/pulls?q=is%3Apr+is%3Aopen+author%3A${github_username}`;
    }
  });
});

// Amazon.co.jp — shorten to canonical /dp/ASIN URL
siteMapkey(/www\.amazon\.co\.jp/, () => {
  api.mapkey('=s', 'Shorten to /dp/ASIN', () => {
    const asin = document.querySelector("[name='ASIN'], [name='ASIN.0']")?.value;
    if (asin) location.href = `https://www.amazon.co.jp/dp/${asin}`;
  });
});

// Hatena Bookmark hotentry — date navigation
siteMapkey(/^https:\/\/b\.hatena\.ne\.jp\/.*\/hotentry\?date/, () => {
  const moveDate = (diff) => () => {
    const url     = new URL(location.href);
    const dateTxt = url.searchParams.get('date');
    const [, yyyy, mm, dd] = dateTxt.match(/(....)(..)(..)/);
    const date = new Date(parseInt(yyyy), parseInt(mm) - 1, parseInt(dd) + diff);
    url.searchParams.set('date', formatDate(date, 'YYYYMMDD'));
    location.href = url.href;
  };
  api.mapkey(']]', 'Next date', moveDate(1));
  api.mapkey('[[', 'Prev date', moveDate(-1));
});

// YouTube
siteMapkey(/youtube\.com/, () => {
  api.mapkey('F', 'Toggle fullscreen',
    clickElm('.ytp-fullscreen-button.ytp-button'));

  api.mapkey('K', 'Toggle play/pause', () => {
    const video = document.querySelector('video');
    if (video) video.paused ? video.play() : video.pause();
  });

  // NEW: skip forward/backward 10 s without touching the progress bar
  api.mapkey('.', 'Skip forward 10s', () => {
    const video = document.querySelector('video');
    if (video) video.currentTime += 10;
  });
  api.mapkey(',', 'Skip backward 10s', () => {
    const video = document.querySelector('video');
    if (video) video.currentTime -= 10;
  });

  // NEW: speed control
  api.mapkey('>', 'Increase playback speed', () => {
    const video = document.querySelector('video');
    if (video) { video.playbackRate = Math.min(video.playbackRate + 0.25, 4); api.Front.showBanner(`${video.playbackRate}x`); }
  });
  api.mapkey('<', 'Decrease playback speed', () => {
    const video = document.querySelector('video');
    if (video) { video.playbackRate = Math.max(video.playbackRate - 0.25, 0.25); api.Front.showBanner(`${video.playbackRate}x`); }
  });

  api.mapkey('gH', 'Go to Subscriptions',
    () => { location.href = 'https://www.youtube.com/feed/subscriptions?flow=2'; });
  api.mapkey('gT', 'Go to Trending',
    () => { location.href = 'https://www.youtube.com/feed/trending'; });
  api.mapkey('gL', 'Go to Library',
    () => { location.href = 'https://www.youtube.com/feed/library'; });
  api.mapkey('gW', 'Go to Watch Later',
    () => { location.href = 'https://www.youtube.com/playlist?list=WL'; });
});

// Disable bindings on sites with their own keyboard UX
unmapIfMatch(
  /^https?:\/\/(mail\.google\.com|twitter\.com|feedly\.com|www\.figma\.com\/file)/,
  ['E', 'R', 'd', 'u', 'T', 'f', 'F', 'C', 'x', 'S', 'H', 'L', 'cm', 'co', 'ch', ',t', ',m']
);

// Amazon Video — don't shadow video player keys
unmapIfMatch(/^https:\/\/www\.amazon\.co\.jp\/gp\/video\//, ['d', 's', 'z', 'x', 'r', 'g']);

// =============================================================================
// Site Help System
// =============================================================================

const siteHelps = [
  { pattern: /speakerdeck\.com/, help: ['[ / ]: Slide navigation'] },
  { pattern: /slideshare\.net/,  help: ['[ / ]: Slide navigation'] },
  { pattern: /booklog\.jp/,      help: ['[ / ]: Reviews', 'd: Mark as read', 'R: Kindle integration'] },
  { pattern: /youtube\.com/,     help: ['F: Fullscreen', 'K: Play/Pause', '. / ,: ±10s', '> / <: Speed ±0.25x', 'gH: Subscriptions', 'gT: Trending', 'gW: Watch Later'] },
  { pattern: /amazon\.co\.jp/,   help: ['=s: Shorten to /dp/ASIN'] },
  { pattern: /b\.hatena\.ne\.jp/, help: ['[[ / ]]: Move between dates'] },
  { pattern: /github\.com/,      help: ['ga: Assigned PRs', 'gr: Review-requested PRs', 'gm: My open PRs', ';dw: Open DeepWiki'] },
  { pattern: /trotto\.io/,       help: [';gol: Open a Trotto Go Link'] },
  { pattern: /.*/,               help: 'No site-specific help available.' },
];

api.mapkey(';h', '#00Show site-specific help', () => {
  const matched = siteHelps.find((site) => site.pattern.test(location.href));
  if (matched) {
    const helpText = Array.isArray(matched.help)
      ? matched.help.map((line) => escapeForAlias(line)).join('<br>')
      : escapeForAlias(matched.help);
    api.Front.showPopup(helpText);
  } else {
    api.Front.showPopup('No site-specific help available.');
  }
});

// =============================================================================
// Utilities
// =============================================================================

// Show current date/time
api.mapkey(';dd', 'Display current date and time', function () {
  const p     = (n) => String(n).padStart(2, '0');
  const today = new Date();
  const month = p(today.getMonth() + 1);
  const date  = p(today.getDate());
  const day   = ['日', '月', '火', '水', '木', '金', '土'][today.getDay()];
  const hour  = p(today.getHours());
  const mins  = p(today.getMinutes());
  api.Front.showPopup(`${month}月${date}日(${day}) ${hour}:${mins}`);
});

// NEW: Toggle dark mode via CSS inversion (handy on bright documentation sites)
api.mapkey(';dm', 'Toggle dark mode inversion', function () {
  const el = document.documentElement;
  const current = el.style.filter;
  el.style.filter = current === 'invert(1) hue-rotate(180deg)' ? '' : 'invert(1) hue-rotate(180deg)';
  api.Front.showBanner('Dark mode ' + (el.style.filter ? 'ON' : 'OFF'));
});

// NEW: Increase / decrease page zoom
api.mapkey('zi', 'Zoom in', () => {
  const z = parseFloat(document.body.style.zoom || 1);
  document.body.style.zoom = (z + 0.1).toFixed(1);
});
api.mapkey('zo', 'Zoom out', () => {
  const z = parseFloat(document.body.style.zoom || 1);
  document.body.style.zoom = Math.max(0.3, z - 0.1).toFixed(1);
});
api.mapkey('z0', 'Reset zoom', () => {
  document.body.style.zoom = 1;
});

// =============================================================================
// Theme — Monokai
// =============================================================================

const hintsCss = `
  font-size: 13pt;
  font-family: 'JetBrains Mono NL', 'Cascadia Code', 'Helvetica Neue', Helvetica, Arial, sans-serif;
  border: 0px;
  border-radius: 10px;
  color: #e6db74 !important;
  background: #191724;
  background-color: #191724;
`;
api.Hints.style(hintsCss);
api.Hints.style(hintsCss, 'text');

settings.theme = `
:root {
  --font: 'JetBrains Mono NL', monospace;
  --font-size: 12;
  --font-weight: normal;

  /* Monokai */
  --fg:         #F8F8F2;
  --bg:         #272822;
  --bg-dark:    #1D1E19;
  --border:     #2D2E2E;
  --main-fg:    #F92660;
  --accent-fg:  #E6DB74;
  --info-fg:    #A6E22E;
  --select:     #556172;
}

.sk_theme {
  background: var(--bg);
  color: var(--fg);
  border-color: var(--border);
  font-family: var(--font);
  font-size: var(--font-size);
  font-weight: var(--font-weight);
}

input { font-family: var(--font); font-weight: var(--font-weight); }
.sk_theme tbody      { color: var(--fg); }
.sk_theme input      { color: var(--fg); }

#sk_hints .begin     { color: var(--accent-fg) !important; }

#sk_tabs .sk_tab      { background: var(--bg-dark); border: 1px solid var(--border); }
#sk_tabs .sk_tab_title { color: var(--fg); }
#sk_tabs .sk_tab_url   { color: var(--main-fg); }
#sk_tabs .sk_tab_hint  { background: var(--bg); border: 1px solid var(--border); color: var(--accent-fg); }

.sk_theme #sk_frame   { background: var(--bg); opacity: 0.2; color: var(--accent-fg); }

/* Omnibar */
.sk_theme .title             { color: var(--accent-fg); }
.sk_theme .url               { color: var(--main-fg); }
.sk_theme .annotation        { color: var(--accent-fg); }
.sk_theme .omnibar_highlight { color: var(--accent-fg); }
.sk_theme .omnibar_timestamp { color: var(--info-fg); }
.sk_theme .omnibar_visitcount { color: var(--accent-fg); }

.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) { background: var(--bg-dark); }
.sk_theme #sk_omnibarSearchResult ul li.focused        { background: var(--border); }
.sk_theme #sk_omnibarSearchArea                        { border-top-color: var(--border); border-bottom-color: var(--border); }
.sk_theme #sk_omnibarSearchArea input,
.sk_theme #sk_omnibarSearchArea span                   { font-size: var(--font-size); }
.sk_theme .separator                                   { color: var(--accent-fg); }

/* Banner */
#sk_banner {
  font-family: var(--font);
  font-size: var(--font-size);
  font-weight: var(--font-weight);
  background: var(--bg);
  border-color: var(--border);
  color: var(--fg);
  opacity: 0.9;
}

/* Keystroke popup */
#sk_keystroke                { background-color: var(--bg); }
.sk_theme kbd .candidates    { color: var(--info-fg); }
.sk_theme span.annotation    { color: var(--accent-fg); }

/* Translation bubble */
#sk_bubble                   { background-color: var(--bg) !important; color: var(--fg) !important; border-color: var(--border) !important; }
#sk_bubble *                 { color: var(--fg) !important; }
#sk_bubble div.sk_arrow div:nth-of-type(1) { border-top-color: var(--border) !important; border-bottom-color: var(--border) !important; }
#sk_bubble div.sk_arrow div:nth-of-type(2) { border-top-color: var(--bg) !important;     border-bottom-color: var(--bg) !important; }

/* Search / Find bar */
#sk_status, #sk_find { font-size: var(--font-size); border-color: var(--border); }

.sk_theme kbd {
  background: var(--bg-dark);
  border-color: var(--border);
  box-shadow: none;
  color: var(--fg);
}
.sk_theme .feature_name span { color: var(--main-fg); }

/* ACE editor */
#sk_editor { background: var(--bg-dark) !important; height: 50% !important; }
.ace_dialog-bottom { border-top: 1px solid var(--bg) !important; }
.ace-chrome .ace_print-margin,
.ace_gutter, .ace_gutter-cell, .ace_dialog { background: var(--bg) !important; }
.ace-chrome                                { color: var(--fg) !important; }
.ace_gutter, .ace_dialog                  { color: var(--fg) !important; }
.ace_cursor                               { color: var(--fg) !important; }
.normal-mode .ace_cursor                  { background-color: var(--fg) !important; border: var(--fg) !important; opacity: 0.7 !important; }
.ace_marker-layer .ace_selection          { background: var(--select) !important; }
.ace_editor, .ace_dialog span, .ace_dialog input {
  font-family: var(--font);
  font-size: var(--font-size);
  font-weight: var(--font-weight);
}
`;
