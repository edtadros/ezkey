(function registerWebMcp() {
  var nav = typeof navigator !== "undefined" ? navigator : null;
  var doc = typeof document !== "undefined" ? document : null;
  var mc = (nav && nav.modelContext) || (doc && doc.modelContext);
  if (!mc || typeof mc.registerTool !== "function") return;

  function json(path) {
    return fetch(path, { headers: { Accept: "application/json" } }).then(function (res) {
      return res.json().then(function (body) {
        if (!res.ok) throw new Error(body.detail || body.message || res.statusText);
        return body;
      });
    });
  }

  try {
    mc.registerTool({
      name: "get_overview",
      description: "Return a short description of ezkey and where to get the source.",
      inputSchema: { type: "object", properties: {}, additionalProperties: false },
      execute: function () {
        return json("/api/v1/overview");
      }
    });
    mc.registerTool({
      name: "get_build_instructions",
      description: "Return commands to clone and build ezkey on macOS.",
      inputSchema: { type: "object", properties: {}, additionalProperties: false },
      execute: function () {
        return json("/api/v1/build");
      }
    });
    mc.registerTool({
      name: "get_agent_brief",
      description: "Return the repo URL, disclaimer, and clone/build steps an agent must present before running ezkey.",
      inputSchema: { type: "object", properties: {}, additionalProperties: false },
      execute: function () {
        return json("/api/v1/agent-brief");
      }
    });
    mc.registerTool({
      name: "get_page",
      description: "Return Markdown for a site page.",
      inputSchema: {
        type: "object",
        properties: {
          page: {
            type: "string",
            description: "One of home, about, contact, privacy, security, glossary, developers, auth",
            enum: ["home", "about", "contact", "privacy", "security", "glossary", "developers", "auth"]
          }
        },
        required: ["page"],
        additionalProperties: false
      },
      execute: function (input) {
        var page = (input && input.page) || "home";
        return json("/api/v1/pages/" + encodeURIComponent(page));
      }
    });
  } catch (err) {
    if (typeof console !== "undefined" && console.warn) console.warn("webmcp: registration failed", err);
  }
})();
