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
    .replace("%URL%", location.href)
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
api.addSearchAlias(
  "a3",
  "Google 3ヶ月以内",
  "https://www.google.co.jp/search?q={0}&tbs=qdr:m3,lr:lang_1ja&lr=lang_ja"
);

// MDN
api.addSearchAlias(
  "amdn",
  "MDN",
  "https://developer.mozilla.org/search?q=",
  "s",
  "https://developer.mozilla.org/api/v1/search?q=",
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
siteMapkey(/github\.com/, () => {
  api.mapkey(
    "ga",
    "Go to assigned PRs for current GitHub repo",
    function goToAssignedPRs() {
      const match = window.location.href.match(
        /^https:\/\/github\.com\/([^\/]+)\/([^\/?#]+)/
      );
      if (match && match[1] == github_username) {
        const user = match[1];
        const repo = match[2];
        const assignedUrl = `https://github.com/${user}/${repo}/pulls?q=is%3Apr+is%3Aopen+assignee%3A${user}+author%3A${user}`;
        window.location.href = assignedUrl;
      } else {
        Front.showPopup("Not a valid GitHub repo URL.");
      }
    }
  );
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

/**
 * Theme customization
 */
const hintsCss = `
  font-size: 13pt;
  font-family: 'JetBrains Mono NL', 'Cascadia Code', 'Helvetica Neue', Helvetica, Arial, sans-serif;
  border: 0px;
  border-radius: 4px;
  color: #e0def4 !important;
  background: #191724;
  background-color: #191724;
`;
api.Hints.style(hintsCss);
api.Hints.style(hintsCss, "text");
settings.theme = `
  .sk_theme {
    background: #191724;
    color: #e0def4;
  }
  .sk_theme input {
    color: #e0def4;
  }
  .sk_theme .url {
    color: #c4a7e7;
  }
  .sk_theme .annotation {
    color: #ebbcba;
  }
  .sk_theme kbd {
    background: #26233a;
    color: #e0def4;
  }
  .sk_theme .frame {
    background: #1f1d2e;
  }
  .sk_theme .omnibar_highlight {
    color: #403d52;
  }
  .sk_theme .omnibar_folder {
    color: #e0def4;
  }
  .sk_theme .omnibar_timestamp {
    color: #9ccfd8;
  }
  .sk_theme .omnibar_visitcount {
    color: #9ccfd8;
  }
  .sk_theme .prompt, .sk_theme .resultPage {
    color: #e0def4;
  }
  .sk_theme .feature_name {
    color: #e0def4;
  }
  .sk_theme .separator {
    color: #524f67;
  }
  body {
    margin: 0;

    font-family: "JetBrains Mono NL", "Cascadia Code", "Helvetica Neue", Helvetica, Arial, sans-serif;
    font-size: 12px;
  }
  #sk_omnibar {
    overflow: hidden;
    position: fixed;
    width: 80%;
    max-height: 80%;
    left: 10%;
    text-align: left;
    box-shadow: 0px 2px 10px #21202e;
    z-index: 2147483000;
  }
  .sk_omnibar_middle {
    top: 10%;
    border-radius: 4px;
  }
  .sk_omnibar_bottom {
    bottom: 0;
    border-radius: 4px 4px 0px 0px;
  }
  #sk_omnibar span.omnibar_highlight {
    text-shadow: 0 0 0.01em;
  }
  #sk_omnibarSearchArea .prompt, #sk_omnibarSearchArea .resultPage {
    display: inline-block;
    font-size: 20px;
    width: auto;
  }
  #sk_omnibarSearchArea>input {
    display: inline-block;
    width: 100%;
    flex: 1;
    font-size: 20px;
    margin-bottom: 0;
    padding: 0px 0px 0px 0.5rem;
    background: transparent;
    border-style: none;
    outline: none;
  }
  #sk_omnibarSearchArea {
    display: flex;
    align-items: center;
    border-bottom: 1px solid #524f67;
  }
  .sk_omnibar_middle #sk_omnibarSearchArea {
    margin: 0.5rem 1rem;
  }
  .sk_omnibar_bottom #sk_omnibarSearchArea {
    margin: 0.2rem 1rem;
  }
  .sk_omnibar_middle #sk_omnibarSearchResult>ul {
    margin-top: 0;
  }
  .sk_omnibar_bottom #sk_omnibarSearchResult>ul {
    margin-bottom: 0;
  }
  #sk_omnibarSearchResult {
    max-height: 60vh;
    overflow: hidden;
    margin: 0rem 0.6rem;
  }
  #sk_omnibarSearchResult:empty {
    display: none;
  }
  #sk_omnibarSearchResult>ul {
    padding: 0;
  }
  #sk_omnibarSearchResult>ul>li {
    padding: 0.2rem 0rem;
    display: block;
    max-height: 600px;
    overflow-x: hidden;
    overflow-y: auto;
  }
  .sk_theme #sk_omnibarSearchResult>ul>li:nth-child(odd) {
    background: #1f1d2e;
  }
  .sk_theme #sk_omnibarSearchResult>ul>li.focused {
    background: #26233a;
  }
  .sk_theme #sk_omnibarSearchResult>ul>li.window {
    border: 2px solid #524f67;
    border-radius: 8px;
    margin: 4px 0px;
  }
  .sk_theme #sk_omnibarSearchResult>ul>li.window.focused {
    border: 2px solid #c4a7e7;
  }
  .sk_theme div.table {
    display: table;
  }
  .sk_theme div.table>* {
    vertical-align: middle;
    display: table-cell;
  }
  #sk_omnibarSearchResult li div.title {
    text-align: left;
  }
  #sk_omnibarSearchResult li div.url {
    font-weight: bold;
    white-space: nowrap;
  }
  #sk_omnibarSearchResult li.focused div.url {
    white-space: normal;
  }
  #sk_omnibarSearchResult li span.annotation {
    float: right;
  }
  #sk_omnibarSearchResult .tab_in_window {
    display: inline-block;
    padding: 5px;
    margin: 5px;
    box-shadow: 0px 2px 10px #21202e;
  }
  #sk_status {
    position: fixed;
    bottom: 0;
    right: 20%;
    z-index: 2147483000;
    padding: 4px 8px 0 8px;
    border-radius: 4px 4px 0px 0px;
    border: 1px solid #524f67;
    font-size: 12px;
  }
  #sk_status>span {
    line-height: 16px;
  }
  .expandRichHints span.annotation {
    padding-left: 4px;
    color: #ebbcba;
  }
  .expandRichHints .kbd-span {
    min-width: 30px;
    text-align: right;
    display: inline-block;
  }
  .expandRichHints kbd>.candidates {
    color: #e0def4;
    font-weight: bold;
  }
  .expandRichHints kbd {
    padding: 1px 2px;
  }
  #sk_find {
    border-style: none;
    outline: none;
  }
  #sk_keystroke {
    padding: 6px;
    position: fixed;
    float: right;
    bottom: 0px;
    z-index: 2147483000;
    right: 0px;
    background: #191724;
    color: #e0def4;
  }
  #sk_usage, #sk_popup, #sk_editor {
    overflow: auto;
    position: fixed;
    width: 80%;
    max-height: 80%;
    top: 10%;
    left: 10%;
    text-align: left;
    box-shadow: #21202e;
    z-index: 2147483298;
    padding: 1rem;
  }
  #sk_nvim {
    position: fixed;
    top: 10%;
    left: 10%;
    width: 80%;
    height: 30%;
  }
  #sk_popup img {
    width: 100%;
  }
  #sk_usage>div {
    display: inline-block;
    vertical-align: top;
  }
  #sk_usage .kbd-span {
    width: 80px;
    text-align: right;
    display: inline-block;
  }
  #sk_usage .feature_name {
    text-align: center;
    padding-bottom: 4px;
  }
  #sk_usage .feature_name>span {
    border-bottom: 2px solid #524f67;
  }
  #sk_usage span.annotation {
    padding-left: 32px;
    line-height: 22px;
  }
  #sk_usage * {
    font-size: 10pt;
  }
  kbd {
    white-space: nowrap;
    display: inline-block;
    padding: 3px 5px;
    font: 11px "JetBrains Mono NL", "Cascadia Code", "Helvetica Neue", Helvetica, Arial, sans-serif;
    line-height: 10px;
    vertical-align: middle;
    border: solid 1px #524f67;
    border-bottom-lolor: #524f67;
    border-radius: 3px;
    box-shadow: inset 0 -1px 0 #21202e;
  }
  #sk_banner {
    padding: 0.5rem;
    position: fixed;
    left: 10%;
    top: -3rem;
    z-index: 2147483000;
    width: 80%;
    border-radius: 0px 0px 4px 4px;
    border: 1px solid #524f67;
    border-top-style: none;
    text-align: center;
    background: #191724;
    white-space: nowrap;
    text-overflow: ellipsis;
    overflow: hidden;
    color: #e0def4;
  }
  #sk_tabs {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: transparent;
    overflow: auto;
    z-index: 2147483000;
  }
  div.sk_tab {
    display: inline-flex;
    height: 28px;
    width: 202px;
    justify-content: space-between;
    align-items: center;
    flex-direction: row-reverse;
    border-radius: 3px;
    padding: 10px 20px;
    margin: 5px;
    background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#191724), color-stop(100%,#191724));
    box-shadow: 0px 3px 7px 0px #21202e;
  }
  div.sk_tab_wrap {
    display: inline-block;
    flex: 1;
  }
  div.sk_tab_icon {
    display: inline-block;
    vertical-align: middle;
  }
  div.sk_tab_icon>img {
    width: 18px;
  }
  div.sk_tab_title {
    width: 150px;
    display: inline-block;
    vertical-align: middle;
    font-size: 10pt;
    white-space: nowrap;
    text-overflow: ellipsis;
    overflow: hidden;
    padding-left: 5px;
    color: #e0def4;
  }
  div.sk_tab_url {
    font-size: 10pt;
    white-space: nowrap;
    text-overflow: ellipsis;
    overflow: hidden;
    color: #c4a7e7;
  }
  div.sk_tab_hint {
    display: inline-block;
    float:right;
    font-size: 10pt;
    font-weight: bold;
    padding: 0px 2px 0px 2px;
    background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#191724), color-stop(100%,#191724));
    color: #e0def4;
    border: solid 1px #524f67;
    border-radius: 3px;
    box-shadow: #21202e;
  }
  #sk_tabs.vertical div.sk_tab_hint {
    position: initial;
    margin-inline: 0;
  }
  div.tab_rocket {
    display: none;
  }
  #sk_bubble {
    position: absolute;
    padding: 9px;
    border: 1px solid #524f67;
    border-radius: 4px;
    box-shadow: 0 0 20px #21202e;
    color: #e0def4;
    background-color: #191724;
    z-index: 2147483000;
    font-size: 14px;
  }
  #sk_bubble .sk_bubble_content {
    overflow-y: scroll;
    background-size: 3px 100%;
    background-position: 100%;
    background-repeat: no-repeat;
  }
  .sk_scroller_indicator_top {
    background-image: linear-gradient(#191724, transparent);
  }
  .sk_scroller_indicator_middle {
    background-image: linear-gradient(transparent, #191724, transparent);
  }
  .sk_scroller_indicator_bottom {
    background-image: linear-gradient(transparent, #191724);
  }
  #sk_bubble * {
    color: #e0def4 !important;
  }
  div.sk_arrow>div:nth-of-type(1) {
    left: 0;
    position: absolute;
    width: 0;
    border-left: 12px solid transparent;
    border-right: 12px solid transparent;
    background: transparent;
  }
  div.sk_arrow[dir=down]>div:nth-of-type(1) {
    border-top: 12px solid #524f67;
  }
  div.sk_arrow[dir=up]>div:nth-of-type(1) {
    border-bottom: 12px solid #524f67;
  }
  div.sk_arrow>div:nth-of-type(2) {
    left: 2px;
    position: absolute;
    width: 0;
    border-left: 10px solid transparent;
    border-right: 10px solid transparent;
    background: transparent;
  }
  div.sk_arrow[dir=down]>div:nth-of-type(2) {
    border-top: 10px solid #e0def4;
  }
  div.sk_arrow[dir=up]>div:nth-of-type(2) {
    top: 2px;
    border-bottom: 10px solid #e0def4;
  }
  .ace_editor.ace_autocomplete {
    z-index: 2147483300 !important;
    width: 80% !important;
  }
  @media only screen and (max-width: 767px) {
    #sk_omnibar {
      width: 100%;
      left: 0;
    }
    #sk_omnibarSearchResult {
      max-height: 50vh;
      overflow: scroll;
    }
    .sk_omnibar_bottom #sk_omnibarSearchArea {
      margin: 0;
      padding: 0.2rem;
    }
  }
`;
