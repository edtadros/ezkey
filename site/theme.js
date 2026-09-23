(function () {
  var key = "ezkey-theme";
  var saved = null;
  try { saved = localStorage.getItem(key); } catch (err) {}
  var theme = saved === "light" || saved === "dark"
    ? saved
    : (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
  document.documentElement.setAttribute("data-theme", theme);

  var moon = '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M21 14.5A8.5 8.5 0 0 1 9.5 3a7 7 0 1 0 11.5 11.5z"/></svg>';
  var sun = '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4" fill="currentColor"/><g fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.1 5.1l1.6 1.6M17.3 17.3l1.6 1.6M18.9 5.1l-1.6 1.6M6.7 17.3l-1.6 1.6"/></g></svg>';

  document.addEventListener("DOMContentLoaded", function () {
    var header = document.querySelector("header.top nav") || document.querySelector("header.top");
    if (!header || document.getElementById("theme-toggle")) return;
    var button = document.createElement("button");
    button.type = "button";
    button.id = "theme-toggle";
    button.className = "theme-toggle";
    function paint() {
      var current = document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "light";
      var next = current === "dark" ? "light" : "dark";
      button.innerHTML = next === "dark" ? moon : sun;
      button.setAttribute("aria-label", "Switch to " + next + " mode");
    }
    paint();
    button.addEventListener("click", function () {
      var current = document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "light";
      var next = current === "dark" ? "light" : "dark";
      document.documentElement.setAttribute("data-theme", next);
      try { localStorage.setItem(key, next); } catch (err) {}
      paint();
    });
    header.appendChild(button);
  });
})();
