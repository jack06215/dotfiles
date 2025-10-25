// ブラウザ履歴の最大数
settings.omnibarHistoryCacheSize = 500;
// ビジュアルモードでテキストコピー後にノーマルモードへ
settings.modeAfterYank = 'Normal';
// j/k のスクロール量
settings.scrollStepSize = 100;
// 前/次 のページリンクに一致する正規表現
settings.prevLinkRegex = /((<<|prev(ious)?)|<|‹|«|←|前[のへ]+)/i;
settings.nextLinkRegex = /((>>|next)|>|›|»|→|次[のへ]+)/i;
// ヒント表示位置
settings.hintAlign = 'left';
// ヒントキー表示中にShift押しながらヒントキーで新タブで開く
settings.hintShiftNonActive = true;
// Surfingkeys無効サイト
settings.blocklistPattern = /mail.google.com/i;
// 最近使用した順へ
settings.tabsMRUOrder = false;
settings.historyMUOrder = false;
// 入力ボックスからフォーカスが外れたときにカーソルがあった場所にカーソル
// Xでiで入力ボックスに切り替えるとiが入力され、ヒントキーも表示されるため
settings.cursorAtEndOfInput = false;

api.Hints.setCharacters('asdfwerxcvuionm');

// PassThrough mode 1.5秒間だけSurfingkeys無効
api.mapkey('p', '#0enter ephemeral PassThrough mode to temporarily suppress SurfingKeys', function() {
  api.Normal.passThrough(1500);
});

// -- Utilities --
const unmapKeys = (keys) => keys.forEach((key) => api.unmap(key));
const iunmapKeys = (keys) => keys.forEach((key) => api.iunmap(key));
const escapeMap = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': "&quot;",
  "'": "&#39;",
  "/": "&#x2F;",
  "`": "&#x60;",
  "=": "&#x3D;",
};
const escapeForAlias = (str) =>
  String(str).replace(/[&<>"'`=/]/g, (s) => escapeMap[s]);
const createSuggestionItem = (html, props = {}) => {
  const li = document.createElement("li");
  li.innerHTML = html;
  return { html: li.outerHTML, props };
};
const padZero = (txt) => `0${txt}`.slice(-2);
const formatDate = (date, format = "YYYY/MM/DD hh:mm:ss") =>
  format
    .replace("YYYY", date.getFullYear())
    .replace("MM", padZero(date.getMonth() + 1))
    .replace("DD", padZero(date.getDate()))
    .replace("hh", padZero(date.getHours()))
    .replace("mm", padZero(date.getMinutes()))
    .replace("ss", padZero(date.getSeconds()));

const tabOpenBackground = (url) =>
  api.RUNTIME("openLink", {
    tab: {
      tabbed: true,
      active: false,
    },
    url,
  });

const copyTitleAndUrl = (format) => {
  const text = format

    .replace("%TITLE%", document.title);
  api.Clipboard.write(text);
};
const copyHtmlLink = async () => {
  const title = document.title;
  const url = location.href;
  const html = `<a href="${url}">${title}</a>`;
  const plain = `${title} - ${url}`;

  try {
    await navigator.clipboard.write([
      new ClipboardItem({
        "text/html": new Blob([html], { type: "text/html" }),
        "text/plain": new Blob([plain], { type: "text/plain" }),
      }),
    ]);
    Front.showBanner("Rich Copied: " + title);
  } catch (err) {
    console.error("Copy failed", err);
    Front.showBanner("Copy failed: " + err.message);
  }
};

const googleTranslateTo = (lang = "ja") => {
  const selection = window.getSelection().toString();
  const baseUrl = "https://translate.google.com";
  if (selection === "") {
    api.tabOpenLink(
      `${baseUrl}/translate?js=n&sl=auto&tl=${lang}&u=${location.href}`
    );
  } else {
    api.tabOpenLink(
      `${baseUrl}/?sl=auto&tl=${lang}&text=${encodeURIComponent(selection)}`
    );
  }
};

// -- FW specific -- //
api.mapkey(";gol", "Open a Trotto Go Link", function () {
  const url = window.prompt("Trotto Go Link:");
  if (url && url.trim()) {
    window.location.href = `https://go/${url.trim()}`;
  }
});
api.mapkey(";gof", "Go Link New Tab", function () {
  console.log(`https://go/jira`);
  api.Front.openOmnibar(
    { type: "UserURLs", extra: "Trotto Go Link: " },
    (url) => {
      console.log(`https://go/${url.trim()}`);
    }
  );
});

// ---- Maps ----
api.map(">_r", "r");
api.map(">_E", "E");
api.map(">_R", "R");
api.map(">_S", "S");
api.map("S", "sg"); // Search selected text or use clipboard via Google Search
api.map("r", "gf"); // New tab with current URL
api.map("H", ">_S"); // back in history
api.map("L", "D"); // forward in history
api.map("h", "E"); // previousTab
api.map("l", ">_R"); // nextTab
api.map("R", ">_r"); // reload
api.iunmap(":"); // disable emoji

// disable proxy
unmapKeys(["cp", ";pa", ";pb", ";pc", ";pd", ";ps", ";ap"]);
// disable vim binding in insert mode
iunmapKeys([
  "<Ctrl-a>",
  "<Ctrl-e>",
  "<Ctrl-f>",
  "<Ctrl-b>",
  "<Ctrl-k>",
  "<Ctrl-y>",
]);

// -- Search -- //
// remove Baidu
api.removeSearchAlias("b");
// Amazon
api.addSearchAlias(
  "aam",
  "Amazon.jp",
  "https://www.amazon.co.jp/s?k=",
  "s",
  "https://completion.amazon.co.jp/search/complete?method=completion&search-alias=aps&mkt=6&q=",
  (response) => JSON.parse(response.text)[1]
);

// Google jp 3ヶ月以内
api.addSearchAlias("a3", "Google 3ヶ月以内", "https://www.google.co.jp/search?q={0}&tbs=qdr:m3,lr:lang_1ja&lr=lang_ja");

// MDN
api.addSearchAlias("amdn", "MDN", "https://developer.mozilla.org/search?q=", "s", "https://developer.mozilla.org/api/v1/search?q=",
  function (response) {
    console.log(response);
    return res.documents.map((s) =>
      createSuggestionItem(
        `
      <div>
        <div class="title"><strong>${s.title}</strong></div>
        <div style="font-size:0.8em"><em>${s.slug}</em></div>
        <div>${s.summary}</div>
      </div>
    `,
        { url: `https://developer.mozilla.org/${s.locale}/docs/${s.slug}` }
      )
    );
  }
);

// npm
api.addSearchAlias(
  "anpm",
  "npm",
  "https://www.npmjs.com/search?q=",
  "s",
  "https://api.npms.io/v2/search/suggestions?size=20&q=",
  (response) =>
    JSON.parse(response.text).map((s) => {
      let flags = "";
      let desc = "";
      let stars = "";
      let score = "";
      if (s.package.description) {
        desc = escapeForAlias(s.package.description);
      }
      if (s.score && s.score.final) {
        score = Math.round(Number(s.score.final) * 5);
        stars = "⭐".repeat(score) + "☆".repeat(5 - score);
      }
      if (s.flags) {
        Object.keys(s.flags).forEach((f) => {
          flags += `[<span style='color:#ff4d00'>⚑</span> ${escapeForAlias(
            f
          )}] `;
        });
      }
      return createSuggestionItem(
        `
      <div>
        <style>.title>em { font-weight: bold; }</style>
        <div class="title">${s.highlight}</div>
        <div>
          <span style="font-size:1.5em;line-height:1em">${stars}</span>
          <span>${flags}</span>
        </div>
        <div>${desc}</div>
      </div>
    `,
        { url: s.package.links.npm }
      );
    })
);

const LIBRARIES_IO_API_KEY = "asjdfklasdjfklajsdfkl";

api.addSearchAlias(
  "apy",
  "PyPI via Libraries.io",
  "https://pypi.org/project/",
  "s",
  `https://libraries.io/api/search?q=&api_key=${LIBRARIES_IO_API_KEY}`,
  (response) => {
    const results = JSON.parse(response.text);
    return results
      .filter((r) => r.platform === "Pypi")
      .slice(0, 10)
      .map((pkg) =>
        createSuggestionItem(
          `
          <div>
            <div class="title"><strong>${escapeForAlias(
              pkg.name
            )}</strong></div>
            <div>${escapeForAlias(pkg.description || "")}</div>
          </div>
        `,
          { url: `https://pypi.org/project/${pkg.name}/` }
        )
      );
  }
);

// Python 言語リファレンス
api.addSearchAlias('pp', 'python-言語リファレンス', 'https://docs.python.org/3/search.html?q=');
api.mapkey('opp', 'Search with alias python 言語リファレンス', function() {
  api.Front.openOmnibar({type: 'SearchEngine', extra: 'pp'});
});

// -- Key mappings -- //
api.mapkey("cm", "#7Copy title and link to markdown", () => {
  copyTitleAndUrl("[%TITLE%](%URL%)");
});

api.unmap(";t");
api.mapkey(";tj", "#14Translate to Japanese", () => googleTranslateTo("ja"));
api.mapkey(";te", "#14Translate to English", () => googleTranslateTo("en"));
api.mapkey(";tch", "#14Translate to Chinese", () => googleTranslateTo("zh-TW"));
api.mapkey(
  ";dw",
  "deepWiki: Go to DeepWiki for this GitHub repo",
  function deepWiki() {
    const match = window.location.href.match(
      /^https:\/\/github\.com\/([^\/]+)\/([^\/?#]+)/
    );
    if (match) {
      const user = match[1];
      const repo = match[2];
      const deepwikiUrl = `https://deepwiki.com/${user}/${repo}`;
      window.open(deepwikiUrl, "_blank");
    } else {
      api.Front.showPopup("deepWiki: Not a valid GitHub repo URL.");
    }
  }
);

// === Helpers ===
const clickElm = (selector) => () => document.querySelector(selector)?.click();
const clickInIframe = (iframeSelector, targetSelector) => () => {
  const iframe = document.querySelector(iframeSelector);
  const iframeDoc = iframe?.contentWindow?.document;
  iframeDoc?.querySelector(targetSelector)?.click();
};

/**
 *
 * @param {string} pattern - Regular expression to match the URL.
 * @param {function()} fn - Function to execute if the pattern matches.
 */
const siteMapkey = (pattern, fn) => {
  if (pattern.test(location.href)) fn();
};

/**
 * Unmap keys if the current URL matches the given pattern.
 * @param {string} pattern - Regular expression to match the URL.
 * @param {Array} keys - Array of keys to unmap if the pattern matches.
 */
const unmapIfMatch = (pattern, keys) => {
  if (pattern.test(location.href)) unmapKeys(keys);
};

// === Site-Specific Mappings ===

// speakerdeck.com
siteMapkey(/speakerdeck\.com/, () => {
  api.mapkey(
    "]",
    "next page",
    clickInIframe(".speakerdeck-iframe", ".sd-player-next")
  );
  api.mapkey(
    "[",
    "prev page",
    clickInIframe(".speakerdeck-iframe", ".sd-player-previous")
  );
});

// slideshare.net
siteMapkey(/www\.slideshare\.net/, () => {
  api.mapkey("]", "next page", clickElm("#btnNext"));
  api.mapkey("[", "prev page", clickElm("#btnPrevious"));
});

// booklog.jp
siteMapkey(/booklog\.jp/, () => {
  api.mapkey("]", "next review page", clickElm("#modal-review-next"));
  api.mapkey("[", "prev review page", clickElm("#modal-review-prev"));
  api.mapkey("d", "Mark as read", clickElm("#status3"));
  api.mapkey("R", "Open in Kindle", () => {
    const asin = document
      .querySelector(".item-area-info-title a")
      ?.getAttribute("href")
      ?.replace(/.*\//, "");
    if (asin) {
      RUNTIME("openLink", {
        tab: { tabbed: true },
        url: `https://read.amazon.co.jp/?asin=${asin}`,
      });
    }
  });
});

// GitHub
const github_username = "jack06215";
const github_profile = ["jack06215", "flywheel-jp"];

siteMapkey(/github\.com/, () => {
  api.mapkey("ga", "Go to assigned PRs for current GitHub repo", function goToAssignedPRs() {
    const match = window.location.href.match(/^https:\/\/github\.com\/([^\/]+)\/([^\/?#]+)/);
    if (match && github_profile.includes(match[1])) {
      const user = match[1];
      const repo = match[2];
      const assignedUrl = `https://github.com/${user}/${repo}/pulls?q=is%3Apr+is%3Aopen+assignee%3A${github_username}`;
      window.location.href = assignedUrl;
    } else {
      api.Front.showPopup("Not a valid GitHub repo URL.");
    }
  });
});

// amazon.co.jp product page
siteMapkey(/www\.amazon\.co\.jp/, () => {
  api.mapkey("=s", "Shorten to /dp/ASIN", () => {
    const asin = document.querySelector(
      "[name='ASIN'], [name='ASIN.0']"
    )?.value;
    if (asin) location.href = `https://www.amazon.co.jp/dp/${asin}`;
  });
});

// Hatena hotentry date navigation
siteMapkey(/^https:\/\/b\.hatena\.ne\.jp\/.*\/hotentry\?date/, () => {
  const moveDate = (diff) => () => {
    const url = new URL(location.href);
    const dateTxt = url.searchParams.get("date");
    const [_, yyyy, mm, dd] = dateTxt.match(/(....)(..)(..)/);
    const date = new Date(
      parseInt(yyyy),
      parseInt(mm) - 1,
      parseInt(dd) + diff
    );
    url.searchParams.set("date", formatDate(date, "YYYYMMDD"));
    location.href = url.href;
  };
  api.mapkey("]]", "next date", moveDate(1));
  api.mapkey("[[", "prev date", moveDate(-1));
});

// youtube.com
siteMapkey(/youtube\.com/, () => {
  api.mapkey(
    "F",
    "Toggle fullscreen",
    clickElm(".ytp-fullscreen-button.ytp-button")
  );

  api.mapkey("K", "Toggle play/pause", () => {
    const video = document.querySelector("video");
    if (video) video.paused ? video.play() : video.pause();
  });

  api.mapkey("gH", "Go to Subscriptions", () => {
    location.href = "https://www.youtube.com/feed/subscriptions?flow=2";
  });
  api.mapkey("gT", "Go to Trending", () => {
    location.href = "https://www.youtube.com/feed/trending";
  });

  api.mapkey("gL", "Go to Library", () => {
    location.href = "https://www.youtube.com/feed/library";
  });

  api.mapkey("gW", "Go to Watch Later", () => {
    location.href = "https://www.youtube.com/playlist?list=WL";
  });
});

// Disable bindings for specific sites
unmapIfMatch(
  /^https?:\/\/(mail\.google\.com|twitter\.com|feedly\.com|www\.figma\.com\/file)/,
  [
    "E",
    "R",
    "d",
    "u",
    "T",
    "f",
    "F",
    "C",
    "x",
    "S",
    "H",
    "L",
    "cm",
    "co",
    "ch",
    ",t",
    ",m",
  ]
);

// Disable video speed keys on Amazon Video
unmapIfMatch(/^https:\/\/www\.amazon\.co\.jp\/gp\/video\//, [
  "d",
  "s",
  "z",
  "x",
  "r",
  "g",
]);

// Site Help Popup
const siteHelps = [
  {
    pattern: /speakerdeck\.com/,
    help: ["[ / ]: Slide navigation"],
  },
  {
    pattern: /slideshare\.net/,
    help: ["[ / ]: Slide navigation"],
  },
  {
    pattern: /booklog\.jp/,
    help: ["[ / ]: Reviews", "d: Mark as read", "R: Kindle integration"],
  },
  {
    pattern: /youtube\.com/,
    help: [
      "F: Fullscreen",
      "K: Play/Pause",
      "gH: Subscriptions",
      "gT: Trending",
      "gW: Watch Later",
    ],
  },
  {
    pattern: /amazon\.co\.jp/,
    help: ["=s: Shorten to /dp/ASIN"],
  },
  {
    pattern: /b\.hatena\.ne\.jp/,
    help: ["[[ / ]]: Move between dates"],
  },
  {
    pattern: /github\.com/,
    help: ["ga: Go to assigned PRs for current repo"],
  },
  {
    pattern: /trotto\.io/,
    help: [";gol: Open a Trotto Go Link"],
  },
  {
    pattern: /.*/,
    help: "No site-specific help available.",
  },
];

api.mapkey(";h", "#00Show site-specific help", () => {
  const url = location.href;
  const matched = siteHelps.find((site) => site.pattern.test(url));

  if (matched) {
    const helpText = Array.isArray(matched.help)
      ? matched.help.map((line) => escapeForAlias(line)).join("<br>")
      : escapeForAlias(matched.help);
    api.Front.showPopup(helpText);
  } else {
    api.Front.showPopup("No site-specific help available.");
  }
});

api.mapkey(';dd', 'display the date, day, and time', function () {
  const padZero2 = (num) => String(num).padStart(2, '0');
  const today = new Date();
  const month = padZero2(today.getMonth() + 1);
  const date = padZero2(today.getDate());
  const day = today.getDay();
  const dayList = ['日', '月', '火', '水', '木', '金', '土'];
  const dayWeek = dayList[day];
  const hour = padZero2(today.getHours());
  const minutes = padZero2(today.getMinutes());
  const formatTodayDate = `${month}月${date}日(${dayWeek}) ${hour}:${minutes}`;
api.Front.showPopup(formatTodayDate);
});

// Disable SurfingKeys on Google editors
// settings.blocklistPattern = /https?:\/\/(?:docs\.google\.com\/(?:document|spreadsheets|presentation)\/|slides\.google\.com\/)/i;

/**
 * Theme customization
 */
// ---- Hints ----
// Hints have to be defined separately
// Uncomment to enable

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
api.Hints.style(hintsCss, "text");

settings.theme = `
/* Edit these variables for easy theme making */
:root {
  /* Font */
  --font: 'JetBrains Mono NL', monospace;
  --font-size: 12;
  --font-weight: normal;

  /* -------------- */
  /* --- THEMES --- */
  /* -------------- */

  /* -------------------- */
  /* -- Tomorrow Night -- */
  /* -------------------- */
  /* -- DELETE LINE TO ENABLE THEME
  --fg: #C5C8C6;
  --bg: #282A2E;
  --bg-dark: #1D1F21;
  --border: #373b41;
  --main-fg: #81A2BE;
  --accent-fg: #52C196;
  --info-fg: #AC7BBA;
  --select: #585858;
  -- DELETE LINE TO ENABLE THEME */

  /* Unused Alternate Colors */
  /* --cyan: #4CB3BC; */
  /* --orange: #DE935F; */
  /* --red: #CC6666; */
  /* --yellow: #CBCA77; */

  /* -------------------- */
  /* --      NORD      -- */
  /* -------------------- */
  /* -- DELETE LINE TO ENABLE THEME
  --fg: #E5E9F0;
  --bg: #3B4252;
  --bg-dark: #2E3440;
  --border: #4C566A;
  --main-fg: #88C0D0;
  --accent-fg: #A3BE8C;
  --info-fg: #5E81AC;
  --select: #4C566A;
  -- DELETE LINE TO ENABLE THEME */

  /* Unused Alternate Colors */
  /* --orange: #D08770; */
  /* --red: #BF616A; */
  /* --yellow: #EBCB8B; */

  /* -------------------- */
  /* --    DOOM ONE    -- */
  /* -------------------- */
  /* -- DELETE LINE TO ENABLE THEME
  --fg: #51AFEF;
  --bg: #2E3440;
  --bg-dark: #21242B;
  --border: #2257A0;
  --main-fg: #51AFEF;
  --accent-fg: #98be65;
  --info-fg: #C678DD;
  --select: #4C566A;
  -- DELETE LINE TO ENABLE THEME */

  /* Unused Alternate Colors */
  /* --border-alt: #282C34; */
  /* --cyan: #46D9FF; */
  /* --orange: #DA8548; */
  /* --red: #FF6C6B; */
  /* --yellow: #ECBE7B; */

  /* -------------------- */
  /* --    MONOKAI    -- */
  /* -------------------- */
  --fg: #F8F8F2;
  --bg: #272822;
  --bg-dark: #1D1E19;
  --border: #2D2E2E;
  --main-fg: #F92660;
  --accent-fg: #E6DB74;
  --info-fg: #A6E22E;
  --select: #556172;

  /* Unused Alternate Colors */
  /* --red: #E74C3C; */
  /* --orange: #FD971F; */
  /* --blue: #268BD2; */
  /* --violet: #9C91E4; */
  /* --cyan: #66D9EF; */
}

/* ---------- Generic ---------- */
.sk_theme {
background: var(--bg);
color: var(--fg);
  background-color: var(--bg);
  border-color: var(--border);
  font-family: var(--font);
  font-size: var(--font-size);
  font-weight: var(--font-weight);
}

input {
  font-family: var(--font);
  font-weight: var(--font-weight);
}

.sk_theme tbody {
  color: var(--fg);
}

.sk_theme input {
  color: var(--fg);
}

/* Hints */
#sk_hints .begin {
  color: var(--accent-fg) !important;
}

#sk_tabs .sk_tab {
  background: var(--bg-dark);
  border: 1px solid var(--border);
}

#sk_tabs .sk_tab_title {
  color: var(--fg);
}

#sk_tabs .sk_tab_url {
  color: var(--main-fg);
}

#sk_tabs .sk_tab_hint {
  background: var(--bg);
  border: 1px solid var(--border);
  color: var(--accent-fg);
}

.sk_theme #sk_frame {
  background: var(--bg);
  opacity: 0.2;
  color: var(--accent-fg);
}

/* ---------- Omnibar ---------- */
/* Uncomment this and use settings.omnibarPosition = 'bottom' for Pentadactyl/Tridactyl style bottom bar */
/* .sk_theme#sk_omnibar {
  width: 100%;
  left: 0;
} */

.sk_theme .title {
  color: var(--accent-fg);
}

.sk_theme .url {
  color: var(--main-fg);
}

.sk_theme .annotation {
  color: var(--accent-fg);
}

.sk_theme .omnibar_highlight {
  color: var(--accent-fg);
}

.sk_theme .omnibar_timestamp {
  color: var(--info-fg);
}

.sk_theme .omnibar_visitcount {
  color: var(--accent-fg);
}

.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
  background: var(--bg-dark);
}

.sk_theme #sk_omnibarSearchResult ul li.focused {
  background: var(--border);
}

.sk_theme #sk_omnibarSearchArea {
  border-top-color: var(--border);
  border-bottom-color: var(--border);
}

.sk_theme #sk_omnibarSearchArea input,
.sk_theme #sk_omnibarSearchArea span {
  font-size: var(--font-size);
}

.sk_theme .separator {
  color: var(--accent-fg);
}

/* ---------- Popup Notification Banner ---------- */
#sk_banner {
  font-family: var(--font);
  font-size: var(--font-size);
  font-weight: var(--font-weight);
  background: var(--bg);
  border-color: var(--border);
  color: var(--fg);
  opacity: 0.9;
}

/* ---------- Popup Keys ---------- */
#sk_keystroke {
  background-color: var(--bg);
}

.sk_theme kbd .candidates {
  color: var(--info-fg);
}

.sk_theme span.annotation {
  color: var(--accent-fg);
}

/* ---------- Popup Translation Bubble ---------- */
#sk_bubble {
  background-color: var(--bg) !important;
  color: var(--fg) !important;
  border-color: var(--border) !important;
}

#sk_bubble * {
  color: var(--fg) !important;
}

#sk_bubble div.sk_arrow div:nth-of-type(1) {
  border-top-color: var(--border) !important;
  border-bottom-color: var(--border) !important;
}

#sk_bubble div.sk_arrow div:nth-of-type(2) {
  border-top-color: var(--bg) !important;
  border-bottom-color: var(--bg) !important;
}

/* ---------- Search ---------- */
#sk_status,
#sk_find {
  font-size: var(--font-size);
  border-color: var(--border);
}

.sk_theme kbd {
  background: var(--bg-dark);
  border-color: var(--border);
  box-shadow: none;
  color: var(--fg);
}

.sk_theme .feature_name span {
  color: var(--main-fg);
}

/* ---------- ACE Editor ---------- */
#sk_editor {
  background: var(--bg-dark) !important;
  height: 50% !important;
  /* Remove this to restore the default editor size */
}

.ace_dialog-bottom {
  border-top: 1px solid var(--bg) !important;
}

.ace-chrome .ace_print-margin,
.ace_gutter,
.ace_gutter-cell,
.ace_dialog {
  background: var(--bg) !important;
}

.ace-chrome {
  color: var(--fg) !important;
}

.ace_gutter,
.ace_dialog {
  color: var(--fg) !important;
}

.ace_cursor {
  color: var(--fg) !important;
}

.normal-mode .ace_cursor {
  background-color: var(--fg) !important;
  border: var(--fg) !important;
  opacity: 0.7 !important;
}

.ace_marker-layer .ace_selection {
  background: var(--select) !important;
}

.ace_editor,
.ace_dialog span,
.ace_dialog input {
  font-family: var(--font);
  font-size: var(--font-size);
  font-weight: var(--font-weight);
}
`;
