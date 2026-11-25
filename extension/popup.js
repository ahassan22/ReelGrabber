const api = typeof browser !== "undefined" ? browser : chrome;
const urlEl = document.getElementById("url");
const noteEl = document.getElementById("note");
const audioBtn = document.getElementById("audio");
const videoBtn = document.getElementById("video");
const textBtn = document.getElementById("transcript");
let currentTab = null;

async function init() {
  const tabs = await api.tabs.query({ active: true, currentWindow: true });
  currentTab = tabs[0];
  const url = (currentTab && currentTab.url) || "";
  urlEl.textContent = url || "لا يوجد رابط";
  if (!/^https?:\/\//i.test(url)) {
    audioBtn.disabled = true;
    videoBtn.disabled = true;
    textBtn.disabled = true;
    noteEl.textContent = "افتح صفحة الفيديو أولًا.";
    return;
  }
  if (/facebook\.com/i.test(url) && !/\/(reel|videos|watch)/i.test(url)) {
    noteEl.textContent = "على فيسبوك: افتح الفيديو في صفحته الخاصة (اضغط على الريل أو على وقت النشر) حتى يكون الرابط رابط الفيديو نفسه.";
  }
}

function send(mode) {
  if (!currentTab) return;
  const target = "reelgrab:?mode=" + mode + "&url=" + encodeURIComponent(currentTab.url);
  api.tabs.update(currentTab.id, { url: target });
  window.close();
}

audioBtn.addEventListener("click", () => send("audio"));
videoBtn.addEventListener("click", () => send("video"));
textBtn.addEventListener("click", () => send("transcript"));
init();
