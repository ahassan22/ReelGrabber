const api = typeof browser !== "undefined" ? browser : chrome;

const VIDEO_LINK = /(facebook\.com\/(reel|watch|.*\/videos\/)|fb\.watch\/|youtube\.com\/(watch|shorts)|youtu\.be\/|instagram\.com\/(reel|p)\/|tiktok\.com\/|x\.com\/.*\/status\/|twitter\.com\/.*\/status\/)/i;

function createMenus() {
  api.contextMenus.removeAll(() => {
    const contexts = ["page", "link", "video"];
    api.contextMenus.create({ id: "rg-audio", title: "ReelGrabber: الصوت MP3", contexts });
    api.contextMenus.create({ id: "rg-video", title: "ReelGrabber: فيديو كامل", contexts });
    api.contextMenus.create({ id: "rg-transcript", title: "ReelGrabber: النص فقط", contexts });
  });
}

api.runtime.onInstalled.addListener(createMenus);
api.runtime.onStartup.addListener(createMenus);

api.contextMenus.onClicked.addListener((info, tab) => {
  const mode = info.menuItemId === "rg-video" ? "video" : info.menuItemId === "rg-transcript" ? "transcript" : "audio";
  // Prefer the link under the mouse when it points to a video (for example a reel in the news feed),
  // otherwise use the address of the page itself.
  let url = info.pageUrl || (tab && tab.url) || "";
  if (info.linkUrl && VIDEO_LINK.test(info.linkUrl)) url = info.linkUrl;
  if (!/^https?:\/\//i.test(url) || !tab) return;
  api.tabs.update(tab.id, { url: "reelgrab:?mode=" + mode + "&url=" + encodeURIComponent(url) });
});
