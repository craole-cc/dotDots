// DMS owns these local assets. Refresh them without changing VS Code settings.
(() => {
  let revision;
  let refreshing = false;
  async function refresh() {
    if (refreshing || !document.body) return;
    refreshing = true;
    try {
      const stateURL = new URL("dotdots-wallpaper.json", document.baseURI);
      stateURL.searchParams.set("t", Date.now());
      const response = await fetch(stateURL, { cache: "no-store" });
      if (!response.ok) return;
      const state = await response.json();
      if (typeof state.revision !== "string" || !Number.isFinite(state.opacity)
          || state.opacity < 0 || state.opacity > 1) return;
      document.documentElement.style.setProperty("--dotdots-editor-opacity", state.opacity);
      if (revision !== state.revision) {
        const imageURL = new URL("dotdots-wallpaper.jpg", document.baseURI);
        imageURL.searchParams.set("v", state.revision);
        document.body.style.setProperty("background-image", `url(${JSON.stringify(imageURL.href)})`, "important");
        document.body.style.setProperty("background-size", "cover", "important");
        document.body.style.setProperty("background-position", "center", "important");
        document.body.style.setProperty("background-repeat", "no-repeat", "important");
        document.body.style.setProperty("opacity", "1", "important");
        revision = state.revision;
      }
    } catch {
      // Keep the last wallpaper while DMS starts or replaces its snapshot.
    } finally {
      refreshing = false;
    }
  }
  void refresh();
  setInterval(refresh, 2000);
})();
