(function () {
  var key = "ezkey-theme";
  var saved = null;
  try { saved = localStorage.getItem(key); } catch (err) {}
  var theme = saved === "light" || saved === "dark"
    ? saved
    : (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
  document.documentElement.setAttribute("data-theme", theme);

  function label(next) {
    return next === "dark" ? "Dark" : "Light";
  }

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
      button.textContent = label(next);
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
