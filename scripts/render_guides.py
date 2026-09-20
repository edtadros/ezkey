#!/usr/bin/env python3
"""Render GEO/AEO guide pages (HTML + Markdown) for ezkey.app."""
from __future__ import annotations

import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
ORIGIN = "https://ezkey.app"
PUBLISHED = "2026-09-20"

NAV = """    <nav>
      <a href="/guides/">Guides</a>
      <a href="/about/">About</a>
      <a href="https://github.com/edtadros/ezkey">Source</a>
    </nav>"""

FOOT = """  <footer>
    <nav>
      <a href="/guides/">Guides</a>
      <a href="/about/">About</a>
      <a href="/contact/">Contact</a>
      <a href="/privacy/">Privacy</a>
      <a href="/security/">Security</a>
    </nav>
    <p>MIT. Provided as-is, without warranty.</p>
  </footer>"""


def inline_md(text: str, escape: bool = True) -> str:
    s = html.escape(text) if escape else text

    def link(m: re.Match[str]) -> str:
        return f'<a href="{html.escape(m.group(2), quote=True)}">{m.group(1)}</a>'

    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", link, s)
    s = re.sub(r"`([^`]+)`", lambda m: f"<code>{m.group(1)}</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    return s


def blocks_to_html(blocks: list) -> str:
    out: list[str] = []
    for b in blocks:
        kind = b[0]
        if kind == "p":
            out.append(f"<p>{inline_md(b[1])}</p>")
        elif kind == "h2":
            ident = b[2] if len(b) > 2 else re.sub(r"[^a-z0-9-]+", "-", b[1].lower()).strip("-")
            out.append(f'<h2 id="{html.escape(ident, quote=True)}">{inline_md(b[1])}</h2>')
        elif kind == "ul":
            items = "".join(f"<li>{inline_md(i)}</li>" for i in b[1])
            out.append(f"<ul>{items}</ul>")
        elif kind == "ol":
            items = "".join(f"<li>{inline_md(i)}</li>" for i in b[1])
            out.append(f"<ol>{items}</ol>")
        elif kind == "pre":
            out.append(f"<pre><code>{html.escape(b[1])}</code></pre>")
        elif kind == "table":
            headers, rows = b[1], b[2]
            th = "".join(f"<th>{inline_md(h)}</th>" for h in headers)
            body = ""
            for row in rows:
                body += "<tr>" + "".join(f"<td>{inline_md(c)}</td>" for c in row) + "</tr>"
            out.append(f"<table><thead><tr>{th}</tr></thead><tbody>{body}</tbody></table>")
        elif kind == "img":
            src, alt = b[1], b[2]
            dark = src.replace(".png", "-dark.png")
            out.append(
                f'<figure><picture><source srcset="{html.escape(dark, quote=True)}" media="(prefers-color-scheme: dark)">'
                f'<img src="{html.escape(src, quote=True)}" width="340" alt="{html.escape(alt, quote=True)}"></picture>'
                f"<figcaption>{inline_md(alt)}</figcaption></figure>"
            )
        elif kind == "related":
            cards = ""
            for href, title, blurb in b[1]:
                cards += (
                    f'<a href="{html.escape(href, quote=True)}">{inline_md(title)}'
                    f"<small>{inline_md(blurb)}</small></a>"
                )
            out.append(f'<div class="related">{cards}</div>')
        else:
            raise ValueError(kind)
    return "\n    ".join(out)


def blocks_to_md(blocks: list) -> str:
    out: list[str] = []
    for b in blocks:
        kind = b[0]
        if kind == "p":
            out.append(b[1])
        elif kind == "h2":
            out.append(f"## {b[1]}")
        elif kind == "ul":
            out.append("\n".join(f"- {i}" for i in b[1]))
        elif kind == "ol":
            out.append("\n".join(f"{n}. {i}" for n, i in enumerate(b[1], 1)))
        elif kind == "pre":
            out.append(f"```\n{b[1]}\n```")
        elif kind == "table":
            headers, rows = b[1], b[2]
            out.append("| " + " | ".join(headers) + " |")
            out.append("| " + " | ".join("---" for _ in headers) + " |")
            for row in rows:
                out.append("| " + " | ".join(row) + " |")
        elif kind == "img":
            out.append(f"![{b[2]}]({ORIGIN}{b[1]})")
        elif kind == "related":
            out.append("\n".join(f"- [{t}]({ORIGIN}{h}): {blurb}" for h, t, blurb in b[1]))
    return "\n\n".join(out)


def schema_graph(page: dict) -> list:
    url = f"{ORIGIN}/{page['slug']}/"
    graph = [
        {
            "@type": "BreadcrumbList",
            "itemListElement": [
                {"@type": "ListItem", "position": 1, "name": "ezkey.app", "item": f"{ORIGIN}/"},
                {"@type": "ListItem", "position": 2, "name": "Guides", "item": f"{ORIGIN}/guides/"},
                {"@type": "ListItem", "position": 3, "name": page["short"], "item": url},
            ],
        },
        {
            "@type": "Article",
            "headline": page["h1"],
            "description": page["description"],
            "datePublished": PUBLISHED,
            "dateModified": PUBLISHED,
            "mainEntityOfPage": url,
            "author": {"@type": "Organization", "name": "ezkey.app", "url": f"{ORIGIN}/"},
            "publisher": {"@id": f"{ORIGIN}/#org"},
        },
        {
            "@type": "FAQPage",
            "mainEntity": [
                {
                    "@type": "Question",
                    "name": q,
                    "acceptedAnswer": {"@type": "Answer", "text": a},
                }
                for q, a in page["faqs"]
            ],
        },
    ]
    if page.get("howto"):
        graph.append(
            {
                "@type": "HowTo",
                "name": page["h1"],
                "description": page["answer"],
                "step": [
                    {"@type": "HowToStep", "position": i, "name": s["name"], "text": s["text"]}
                    for i, s in enumerate(page["howto"], 1)
                ],
            }
        )
    return graph


def render_html(page: dict) -> str:
    url = f"{ORIGIN}/{page['slug']}/"
    md_url = f"{ORIGIN}/{page['slug']}.md"
    faq_html = "".join(
        f"<h2 id=\"faq-{i}\">{inline_md(q)}</h2>\n    <p>{inline_md(a)}</p>"
        for i, (q, a) in enumerate(page["faqs"], 1)
    )
    toc = ""
    if page.get("toc"):
        items = "".join(
            f'<li><a href="#{html.escape(i, quote=True)}">{inline_md(t)}</a></li>'
            for i, t in page["toc"]
        )
        toc = f'<p>On this page</p>\n    <ul class="toc">{items}</ul>'
    ld = {
        "@context": "https://schema.org",
        "@graph": schema_graph(page),
    }
    title = page["title"]
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(title)}</title>
  <meta name="description" content="{html.escape(page['description'])}">
  <meta name="is-agentic-site-type" content="content">
  <meta property="og:title" content="{html.escape(title)}">
  <meta property="og:description" content="{html.escape(page['description'])}">
  <meta property="og:type" content="article">
  <meta property="og:image" content="{ORIGIN}/og.png">
  <meta property="og:url" content="{url}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
  <link rel="canonical" href="{url}">
  <link rel="describedby" href="{ORIGIN}/llms.txt" type="text/plain">
  <link rel="alternate" type="text/markdown" href="{md_url}">
  <link rel="ard" href="{ORIGIN}/.well-known/ard.json">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="/styles.css">
  <script src="/webmcp.js" defer></script>
  <script type="application/ld+json">
  {json.dumps(ld, ensure_ascii=False)}
  </script>
</head>
<body>
  <a class="skip" href="#main">Skip to content</a>
  <header class="top">
    <a class="mark" href="/">ezkey</a>
{NAV}
  </header>
  <main id="main" class="legal">
    <p><a href="/guides/">Guides</a></p>
    <h1>{inline_md(page['h1'])}</h1>
    <div class="answer"><p>{inline_md(page['answer'])}</p></div>
    {toc}
    {blocks_to_html(page['body'])}
    {faq_html}
  </main>
{FOOT}
</body>
</html>
"""


def render_md(page: dict) -> str:
    faqs = "\n\n".join(f"## {q}\n\n{a}" for q, a in page["faqs"])
    return f"""---
title: {page['title']}
description: {page['description']}
---

# {page['h1']}

{page['answer']}

{blocks_to_md(page['body'])}

{faqs}
"""


PAGES: list[dict] = []


def add(**kwargs: object) -> None:
    PAGES.append(kwargs)  # type: ignore[arg-type]


add(
    slug="guides/how-to-save-api-keys-securely-on-mac",
    short="Save API keys securely",
    title="How to save API keys securely on a Mac — ezkey.app",
    h1="How can I save API keys securely on a Mac?",
    description="Put the canonical copy in the macOS login Keychain as a generic password. Skip .env, .zshrc, and git. Menu bar or security CLI.",
    answer="Store the only copy that matters in the login Keychain as a generic password. Do not leave the live value in a project `.env`, in `~/.zshrc`, or in git. On a Mac that already has FileVault and a short screen lock, the Keychain is the store Apple already runs for this job. ezkey.app is a menu bar extra for those same items. The `security` CLI talks to the same file.",
    toc=[
        ("not-env", "What not to do"),
        ("keychain", "What the login Keychain actually is"),
        ("menu-bar", "Save from the menu bar"),
        ("cli", "Save from Terminal without shell history"),
        ("use", "Use the key without leaving it on disk"),
        ("limits", "What this does not protect you from"),
        ("next", "Related answers"),
    ],
    howto=[
        {"name": "Turn on FileVault and a short lock", "text": "System Settings → Privacy & Security → FileVault, and require a password immediately after sleep."},
        {"name": "Pick a Name you can find later", "text": "Use one string such as my-app-api-token. That is Keychain Access Name and Where."},
        {"name": "Save the secret into the login Keychain", "text": "Use ezkey Save, or security add-generic-password with -w last and no value so the CLI prompts."},
        {"name": "Retrieve when you need it", "text": "Menu bar Retrieve, or security find-generic-password -w, then export for one shell only."},
        {"name": "Delete the plaintext leftover", "text": "Remove the key from .env, .zshrc, and any gist or chat log you still control."},
    ],
    faqs=[
        ("Is the login Keychain the same as iCloud Keychain?", "No. Generic passwords ezkey writes go in ~/Library/Keychains/login.keychain-db. That file is local. iCloud Keychain is a different store and is not what ezkey uses."),
        ("Should I put the key in ~/.zshrc after I save it?", "No. Export it for the session you need: export MY_KEY=\"$(security find-generic-password -s NAME -a \"$USER\" -w)\". A line in zshrc with the raw key is a plaintext file again."),
        ("Does ezkey sync keys to other Macs?", "No. There is no account and no server. Copying a Keychain to another machine is a macOS problem, not an ezkey feature."),
        ("Is Always Allow safe?", "Always Allow is a standing grant to that app’s code signature. Use it only for a binary you compiled or a notarized GitHub Release."),
    ],
    body=[
        ("h2", "What not to do", "not-env"),
        ("p", "The usual leak is not a nation-state. It is a file you forgot. A `.env` in a project directory is readable by any process running as you. If that directory is in iCloud Drive, Time Machine, or a zip you mailed, the key travels with it. `echo export OPENAI_API_KEY=sk-... >> ~/.zshrc` writes the same class of file into your home folder. OpenAI’s own setup docs still show that pattern. It keeps the key out of the git repo. It does not keep the key off disk."),
        ("p", "Putting the value after `security add-generic-password -w` on one line is worse in a different way: the secret lands in shell history. Paste from the clipboard (`-w \"$(pbpaste)\"`) or omit `-w`’s argument so `security` prompts."),
        ("h2", "What the login Keychain actually is", "keychain"),
        ("p", "macOS keeps more than one keychain. The one developers mean for local generic passwords is the login Keychain, a file at `~/Library/Keychains/login.keychain-db`. It is encrypted with the login password. It unlocks when you log in. Apple’s Keychain Access app shows those items. The `security` tool reads and writes them. ezkey uses Security.framework against that same file, with Name stored as both label and service so Keychain Access Name and Where match."),
        ("p", "That is not the Data Protection keychain, and it is not iCloud Passwords. Those are different databases. A blog that says “the Keychain is the Secure Enclave” is describing a different item class. Generic passwords in login.keychain-db are file-based. FileVault still matters: if the Mac is off or locked at the FileVault prompt, the disk is ciphertext. After you log in, the login Keychain is available to your session. Screen lock is the control for someone at the desk."),
        ("table", ["Place", "Encrypted at rest", "Shows up in git", "Unlocked with"], [
            [".env in the repo", "No", "Yes, if you commit it", "Anyone who can read the file"],
            ["~/.zshrc export", "No", "Only if you commit dotfiles", "Anyone who can read your home"],
            ["login Keychain generic password", "Yes, login password", "No", "Your Mac session / Keychain ACL"],
            ["1Password / hosted vault", "Yes, vendor model", "No", "Account, often with sync"],
        ]),
        ("h2", "Save from the menu bar", "menu-bar"),
        ("p", "Build [ezkey](https://ezkey.app/) from source, click the key in the menu bar, choose Save, type a Name such as `my-app-api-token`, paste the secret, save. Account is the logged-in Mac user and stays hidden. Retrieve can take a substring of the name and list matches without showing secrets until you pick one. Copy clears in 30 seconds if the pasteboard still holds what ezkey put there."),
        ("img", "/images/panel-save.png", "ezkey Save panel"),
        ("img", "/images/panel-matches.png", "ezkey Retrieve with matching names"),
        ("p", "There is no official unsigned download. Clone https://github.com/edtadros/ezkey and run `./scripts/build-and-run.sh`. Do not grant Keychain access to a random `.app`."),
        ("h2", "Save from Terminal without shell history", "cli"),
        ("pre", "security add-generic-password -U -a \"$USER\" -s \"my-app-api-token\" -w \"$HOME/Library/Keychains/login.keychain-db\"\n# omit the password after -w so security prompts\n# or: -w \"$(pbpaste)\""),
        ("p", "`-s` is the service, which Keychain Access shows as Where. ezkey stores the same string as Name (label) and Where (service). `-a \"$USER\"` is the account ezkey always uses. `-U` updates if the pair already exists. Point at login.keychain-db if you do not want the default keychain to surprise you."),
        ("h2", "Use the key without leaving it on disk", "use"),
        ("pre", "export MY_APP_API_TOKEN=\"$(security find-generic-password -a \"$USER\" -s \"my-app-api-token\" -w \"$HOME/Library/Keychains/login.keychain-db\")\"\n# run the tool\nunset MY_APP_API_TOKEN"),
        ("p", "That export lives in the process environment for that shell. Other processes running as you can still read it while it is set. It is still better than a file that lasts for years in a backup. Do not put the `export` of the raw key into zshrc. Putting the `security find-generic-password` substitution in zshrc will prompt or fail in non-interactive sessions; that is a trade, not a bug."),
        ("h2", "What this does not protect you from", "limits"),
        ("ul", [
            "Malware already running as you, after the Keychain is unlocked.",
            "A secret you paste into Slack, an issue tracker, or a screenshot.",
            "A binary you Always Allow that you did not compile.",
            "Need to share the same key with a team. That is a vault product, not login.keychain-db.",
        ]),
        ("p", "ezkey does not claim otherwise. It is MIT, as-is, no warranty. Read the [security](/security/) notes on Always Allow and the [glossary](/glossary/) for Name, Account, and Where."),
        ("h2", "Related answers", "next"),
        ("related", [
            ("/guides/best-way-to-store-api-keys-on-macos/", "Best way to store API keys on macOS", "How the options compare when you already have a Mac."),
            ("/guides/is-it-safe-to-put-api-keys-in-dotenv/", "Is it safe to put API keys in .env files?", "When a dotenv file is a leak waiting for a zip."),
            ("/guides/security-add-generic-password/", "security add-generic-password", "The CLI the menu extra is compatible with."),
            ("/for/developers/", "ezkey for developers", "Local keys, no account, source you can read."),
        ]),
    ],
)

add(
    slug="guides/best-way-to-store-api-keys-on-macos",
    short="Best way to store keys",
    title="Best way to store API keys on macOS — ezkey.app",
    h1="What is the best way to store API keys on macOS?",
    description="For a solo Mac, the best local store for API keys is the login Keychain. Compare .env, zshrc, security CLI, ezkey, and 1Password without pretending one tool wins every job.",
    answer="For a single Mac you control, the best place for the canonical API key is a generic password in the login Keychain. Use Keychain Access, `security`, or ezkey.app to write it. Use 1Password or a team vault when you must share, audit, or recover across people. Do not treat `.env` or `~/.zshrc` as the canonical copy.",
    toc=[
        ("job", "Name the job before the tool"),
        ("compare", "Options compared"),
        ("solo", "Best default for one Mac"),
        ("team", "When a hosted vault wins"),
        ("ezkey", "Where ezkey fits"),
        ("related", "Related answers"),
    ],
    faqs=[
        ("Is 1Password better than the Keychain?", "For family passwords, sharing, and travel recovery, usually yes. For a local API token that should never leave this Mac, the login Keychain avoids an account and a sync channel."),
        ("Is envchain or direnv enough?", "They are loaders. If they still keep a plaintext file, you have not moved the canonical copy. If they wrap Keychain, they are in the same family as security(1)."),
        ("Should I use the Data Protection keychain instead?", "Only if your app is written for it. launchd helpers and the classic `security` CLI speak the file-based login Keychain. ezkey targets that file on purpose so CLI items round-trip."),
        ("What is the best Name for a key?", "A stable handle you will type later, such as my-app-api-token. ezkey uses that string as Keychain Access Name and Where."),
    ],
    body=[
        ("h2", "Name the job before the tool", "job"),
        ("p", "“Best” is not a brand. It is a match between the threat and the workflow. A Stripe live key on a laptop that also has your personal photos is a different job than a staging token on a CI runner. People ask for the best way to save keys when they have just pasted `sk-live` into a `.env` and felt sick. That job is: one human, one Mac, keys that must not hit GitHub."),
        ("p", "If the job is “the intern in another city needs the same key Monday,” stop. That is a shared vault, a platform secret manager, or a short-lived token. The login Keychain will not email it to them, and ezkey will not either."),
        ("h2", "Options compared", "compare"),
        ("table", ["Method", "Canonical copy lives", "Good for", "Bad for"], [
            [".env in the project", "Disk, often next to code", "Non-secret config", "Anything that spends money if leaked"],
            ["export in ~/.zshrc", "Dotfile on disk", "Non-secret PATH tweaks", "API keys; they sit in backups forever"],
            ["security CLI", "login Keychain", "Scriptable local secrets", "Daily retrieve if you hate flags"],
            ["Keychain Access", "login Keychain", "Seeing what is already there", "Fast save/retrieve of one generic password"],
            ["ezkey menu extra", "Same login Keychain", "Named items you already keep locally", "Teams, iOS, recovery after you forget the password"],
            ["1Password / Bitwarden", "Vendor vault, usually synced", "People, sharing, travel", "Air-gapped local-only policy"],
        ]),
        ("h2", "Best default for one Mac", "solo"),
        ("p", "Turn FileVault on. Require a password when the screen sleeps. Put the key in the login Keychain. Pull it into the environment only for the command that needs it. Delete the plaintext leftovers. That stack uses software Apple already ships. You can inspect the item in Keychain Access. You can round-trip with `security find-generic-password`. You can use [ezkey](https://ezkey.app/) if you want the same item without memorizing `-s` and `-a`."),
        ("p", "PassStore, NoxKey, and similar apps add their own vault format, Touch ID theater, or MCP tools. Some of them still wrap Keychain. Some invent a second encrypted file. A second format is another thing to back up and another binary to trust. For a handful of generic passwords, the login Keychain is enough."),
        ("h2", "When a hosted vault wins", "team"),
        ("p", "1Password, Bitwarden, and company secret managers win when you need: another person to get the value; a phone in the same account; a recovery story that is not “I hope Time Machine ran”; an audit log. They lose when your rule is “this token never leaves the building” or “I will not create an account for a local file.” See [macOS Keychain vs 1Password for API keys](/compare/macos-keychain-vs-1password-for-api-keys/)."),
        ("h2", "Where ezkey fits", "ezkey"),
        ("p", "ezkey is not trying to be the best password manager. It is a menu bar extra for generic passwords in login.keychain-db. Build it from source. It is MIT, as-is. If that is more trust than you want, use Keychain Access and `security` alone. They already work. The extra exists because retrieve-by-substring and a masked field are faster than clicking through Access Control lists when you do this every day."),
        ("h2", "Related answers", "related"),
        ("related", [
            ("/guides/how-to-save-api-keys-securely-on-mac/", "How to save API keys securely on a Mac", "The step-by-step, including the CLI prompt trick."),
            ("/compare/macos-keychain-vs-1password-for-api-keys/", "Keychain vs 1Password", "Honest split: local vs shared."),
            ("/for/local-api-keys/", "For local API keys", "When the key should never leave this Mac."),
            ("/guides/how-to-store-openai-api-key-on-mac/", "Store an OpenAI API key on a Mac", "The same rule, with OPENAI_API_KEY as the example."),
        ]),
    ],
)

add(
    slug="guides/is-it-safe-to-put-api-keys-in-dotenv",
    short=".env files",
    title="Is it safe to put API keys in .env files? — ezkey.app",
    h1="Is it safe to put API keys in .env files?",
    description="A .env file is plaintext. It is fine for non-secrets. It is a common way API keys leak through git, zips, and backups. Use the login Keychain as the canonical store on a Mac.",
    answer="No, not as the canonical store. A `.env` file is plaintext on disk. `.gitignore` only helps if everyone remembers it, including the zip you upload and the colleague’s backup. On a Mac, keep the live key in the login Keychain and, if a tool insists on an environment variable, export it for one process.",
    toc=[
        ("why", "Why dotenv became the default"),
        ("leaks", "How .env files actually leak"),
        ("gitignore", "Why gitignore is not a control"),
        ("instead", "What to do instead on macOS"),
        ("related", "Related answers"),
    ],
    faqs=[
        ("What if the framework requires a .env?", "Give it a file that points at non-secrets, or generate a throwaway env in memory. Do not let the committed example contain a real key."),
        ("Are encrypted .env tools enough?", "They are better than plaintext. You then have a new format, a passphrase, and another binary. The login Keychain is already on the Mac."),
        ("Does Docker make this worse?", "Yes if you COPY a .env into an image or pass secrets as build args that land in layers. Use runtime secrets, not files in the context."),
        ("Can ezkey write a .env for me?", "No. ezkey does not write project files. It talks to the Keychain only."),
    ],
    body=[
        ("h2", "Why dotenv became the default", "why"),
        ("p", "Twelve-factor config said “store config in the environment.” Frameworks translated that into a file named `.env` that the process reads at boot. That is convenient. It is also a file. Files get copied. The pattern spread because it is easy to document: put `DATABASE_URL=` here. Safety was someone else’s `.gitignore`."),
        ("h2", "How .env files actually leak", "leaks"),
        ("ul", [
            "git add -f, or a first commit before gitignore existed.",
            "A zip of the project mailed to a contractor.",
            "iCloud Drive or Dropbox sync of the repo folder.",
            "A screenshot or a screen share that includes the editor tab.",
            "CI caches and Docker layers that ingested the file as a build context.",
        ]),
        ("p", "None of those require a sophisticated attacker. They require a tired Thursday. Once a live key is in git history, rotating the key is the fix, not another gitignore line."),
        ("p", "Dotenv files also train muscle memory in the wrong direction. You open a new repo, copy `.env.example` to `.env`, paste live values, and get to work. Six months later the example file has a real key because someone “just needed it to run.” Code review does not catch a file gitignore hides. The Keychain does not sit next to `src/`."),
        ("h2", "Why gitignore is not a control", "gitignore"),
        ("p", "`.gitignore` is a filter for one tool. It does not encrypt. It does not stop `cp`. It does not stop Time Machine. It does not stop an editor plugin that uploads the workspace. Treat gitignore as politeness toward your future self, not as access control."),
        ("h2", "What to do instead on macOS", "instead"),
        ("p", "Keep the canonical secret in the login Keychain. See [how to save API keys securely on a Mac](/guides/how-to-save-api-keys-securely-on-mac/). If a local server must see `OPENAI_API_KEY`, export it in that terminal from `security find-generic-password` or retrieve it in ezkey and paste once into a process you will kill. Do not recreate a long-lived `.env` that is just the Keychain dumped to disk."),
        ("p", "For a walkthrough with the OpenAI variable name, see [how to store an OpenAI API key on a Mac](/guides/how-to-store-openai-api-key-on-mac/)."),
        ("h2", "Related answers", "related"),
        ("related", [
            ("/guides/how-to-save-api-keys-securely-on-mac/", "How to save API keys securely on a Mac", "Keychain first, leftovers deleted."),
            ("/guides/best-way-to-store-api-keys-on-macos/", "Best way to store API keys on macOS", "The comparison table."),
            ("/for/developers/", "For developers", "Local Keychain items, source you can read."),
            ("/glossary/", "Glossary", "Name, Where, Account."),
        ]),
    ],
)

add(
    slug="guides/how-to-store-openai-api-key-on-mac",
    short="OpenAI API key on a Mac",
    title="How to store an OpenAI API key on a Mac — ezkey.app",
    h1="How do I store an OpenAI API key on a Mac?",
    description="Do not put OPENAI_API_KEY in ~/.zshrc. Save it as a login Keychain generic password, then export it for one shell. ezkey and security(1) use the same item.",
    answer="Do not follow the “append export OPENAI_API_KEY to ~/.zshrc” snippet as the canonical store. Save the key as a generic password in the login Keychain under a Name you choose, then export it into the environment for the shell that talks to the API. ezkey.app and `security` write the same kind of item.",
    toc=[
        ("official", "What OpenAI’s docs tell you"),
        ("save", "Save the key"),
        ("export", "Export for one session"),
        ("rotate", "If it already leaked"),
        ("related", "Related answers"),
    ],
    howto=[
        {"name": "Create or rotate the key at OpenAI", "text": "Use the API keys dashboard. Treat the old key as burned if it was in a file or chat."},
        {"name": "Save into the login Keychain", "text": "ezkey Save with Name openai-api-key, or security add-generic-password with a prompt for -w."},
        {"name": "Export only when needed", "text": "export OPENAI_API_KEY=\"$(security find-generic-password -a \"$USER\" -s openai-api-key -w)\""},
        {"name": "Remove leftovers", "text": "Delete the line from ~/.zshrc and any .env. History: consider wiping the shell history file if you pasted -w on one line."},
    ],
    faqs=[
        ("Can I name the Keychain item OPENAI_API_KEY?", "Yes. ezkey will show that as Name. The environment variable name is independent; you export whatever the SDK reads."),
        ("Does ChatGPT Desktop use this item?", "No. That app has its own sign-in. This is for API keys your local scripts and CLIs use."),
        ("Will this sync to my iPhone?", "Not through ezkey. login.keychain-db is local. iCloud Keychain is a different store."),
        ("Is this official OpenAI software?", "No. ezkey is independent MIT software. OpenAI is a trademark of its owner."),
    ],
    body=[
        ("h2", "What OpenAI’s docs tell you", "official"),
        ("p", "OpenAI’s API key safety page tells macOS users to append `export OPENAI_API_KEY='yourkey'` to `~/.zshrc`. That keeps the key out of the git repository. It still writes a plaintext secret into a dotfile that backup software loves. Plenty of leaked keys started as that one line. Use the dashboard to create the key. Do not use zshrc as the vault."),
        ("p", "The same advice shows up for Anthropic, Gemini, and Stripe: put the token in the environment. The environment is a good *delivery* path for one process. It is a bad *archive*. Once `OPENAI_API_KEY` is in zshrc, every plugin, every `source`, every `bash -lc` from an editor can inherit it. That is convenient for demos and noisy for threat models. Keep the archive in the Keychain. Deliver to the environment on purpose."),
        ("h2", "Save the key", "save"),
        ("p", "In ezkey: Save, Name `openai-api-key`, paste the secret. In Terminal, omit the password on `-w` so it does not hit history:"),
        ("pre", "security add-generic-password -U -a \"$USER\" -s \"openai-api-key\" -w \"$HOME/Library/Keychains/login.keychain-db\""),
        ("p", "Same file Keychain Access lists under login. Same pair ezkey retrieves. See [security add-generic-password](/guides/security-add-generic-password/) for flags."),
        ("h2", "Export for one session", "export"),
        ("pre", "export OPENAI_API_KEY=\"$(security find-generic-password -a \"$USER\" -s \"openai-api-key\" -w \"$HOME/Library/Keychains/login.keychain-db\")\"\n# python / node / curl that reads OPENAI_API_KEY\nunset OPENAI_API_KEY"),
        ("p", "SDKs that call `os.environ[\"OPENAI_API_KEY\"]` work unchanged. You did not invent a new config format. You stopped storing the live value in a file next to your shell config."),
        ("h2", "If it already leaked", "rotate"),
        ("p", "Revoke the key in the OpenAI dashboard first. Then save the new one in the Keychain. Then hunt `.env`, zshrc, GitHub gists, and CI variables. A Keychain item does not un-leak a key that already hit a public repo."),
        ("h2", "Related answers", "related"),
        ("related", [
            ("/guides/how-to-save-api-keys-securely-on-mac/", "How to save API keys securely on a Mac", "The general rule, not just OpenAI."),
            ("/guides/is-it-safe-to-put-api-keys-in-dotenv/", "Are .env files safe?", "Why gitignore is not encryption."),
            ("/for/local-api-keys/", "For local API keys", "When the token must not leave this Mac."),
            ("/for/developers/", "For developers", "Build ezkey and read the Keychain calls."),
        ]),
    ],
)

add(
    slug="guides/security-add-generic-password",
    short="security CLI",
    title="security add-generic-password on macOS — ezkey.app",
    h1="How do I use security add-generic-password?",
    description="security add-generic-password writes a login Keychain item. Use -a, -s, prompt for -w, and the login.keychain-db path. ezkey stores the same Name/Where pair.",
    answer="`security add-generic-password` writes a generic-password item, usually into the login Keychain. Required ideas: `-a` account, `-s` service (Where), `-w` password. Leave `-w` without a value so the tool prompts, or you will put the secret in shell history. ezkey.app uses the same account (your Mac user) and stores Name as both label and service.",
    toc=[
        ("flags", "Flags that matter"),
        ("add", "Add or update"),
        ("find", "Find and print"),
        ("ezkey", "How this maps to ezkey"),
        ("related", "Related answers"),
    ],
    howto=[
        {"name": "Add with a prompt", "text": "security add-generic-password -U -a \"$USER\" -s \"my-app-api-token\" -w \"$HOME/Library/Keychains/login.keychain-db\""},
        {"name": "Find the secret", "text": "security find-generic-password -a \"$USER\" -s \"my-app-api-token\" -w \"$HOME/Library/Keychains/login.keychain-db\""},
        {"name": "Confirm in Keychain Access", "text": "Look under login for Name and Where equal to the service string if you used ezkey, or Where equal to -s if you used security alone."},
    ],
    faqs=[
        ("What is the difference between -s and -l?", "-s is service (Where). -l is label (Name). If you omit -l, label defaults to the service. ezkey sets both to the Name you type."),
        ("Why does find fail after I saved in ezkey?", "Account must match. ezkey always uses the logged-in username. Pass -a \"$USER\"."),
        ("Can I use -A?", "No. -A allows any application to read the item without warning. That is the opposite of careful."),
        ("Does this work over SSH?", "Often you will get a prompt you cannot click. File-based Keychain access from SSH is a known pain. ezkey does not fix that."),
    ],
    body=[
        ("h2", "Flags that matter", "flags"),
        ("table", ["Flag", "Meaning", "ezkey"], [
            ["-a", "Account", "Always the logged-in Mac user; hidden in the UI"],
            ["-s", "Service / Where", "Same string as Name"],
            ["-l", "Label / Name", "Same string as Where"],
            ["-w", "Password", "The secret; prefer a prompt"],
            ["-U", "Update if present", "Save refuses duplicates until you Update"],
            ["keychain path", "Which file", "login.keychain-db"],
        ]),
        ("h2", "Add or update", "add"),
        ("pre", "security add-generic-password -U -a \"$USER\" -s \"my-app-api-token\" -w \\\n  \"$HOME/Library/Keychains/login.keychain-db\""),
        ("p", "ss64 and `man security` document the rest. Creator codes and `-T` trusted apps are how Access Control lists get weird. Default trust includes the creating app. ezkey’s code signature is what Always Allow binds to later."),
        ("p", "A common copy-paste sets `-a` to the service name and `-s` to the key name, or the reverse. Then Keychain Access looks empty when you search the string you remember. Pick a convention and keep it. ezkey’s convention is: the Name you type is both label and service; account is the Mac user. If you already have CLI items with a different account string, Retrieve will not see them until you save under the Mac user or search from Access."),
        ("h2", "Find and print", "find"),
        ("pre", "security find-generic-password -a \"$USER\" -s \"my-app-api-token\" -w \\\n  \"$HOME/Library/Keychains/login.keychain-db\""),
        ("p", "`-w` on find prints only the password. Without it you get attributes. macOS may show a dialog the first time a different app reads the item."),
        ("p", "Printing to stdout is a feature and a footgun. Anything that logs the command output now has the secret. Prefer assigning to a variable, passing to the child, and unsetting. `echo $SECRET` in a shared screen session is how keys travel. ezkey’s copy button is the same class of risk for thirty seconds. That is documented, not hidden."),
        ("h2", "How this maps to ezkey", "ezkey"),
        ("p", "If you save `my-app-api-token` in ezkey, Keychain Access shows that string as Name and Where. `security find-generic-password -s my-app-api-token -a \"$USER\" -w` should print the same secret after you allow access. That round-trip is the point. See [ezkey vs Keychain Access](/compare/ezkey-vs-keychain-access/)."),
        ("h2", "Related answers", "related"),
        ("related", [
            ("/guides/how-to-save-api-keys-securely-on-mac/", "How to save API keys securely on a Mac", "Why the CLI should prompt for -w."),
            ("/glossary/", "Glossary", "Name, Where, Account."),
            ("/compare/ezkey-vs-keychain-access/", "ezkey vs Keychain Access", "Same file, different UI."),
            ("/security/", "Security", "Always Allow and prompts."),
        ]),
    ],
)

add(
    slug="for/developers",
    short="For developers",
    title="macOS Keychain extra for developers — ezkey.app",
    h1="ezkey for developers who already use security(1)",
    description="A macOS menu bar extra that reads and writes the same login Keychain generic passwords as security add-generic-password. Local only. MIT. Build from source.",
    answer="ezkey is for people who already treat the login Keychain as the place for local API tokens and are tired of either Keychain Access or a wall of `security` flags. It is not a cloud vault. You build it. You read the Keychain calls. Items stay in login.keychain-db.",
    toc=[
        ("pain", "The developer reality"),
        ("how", "How ezkey helps"),
        ("not", "What it will not do"),
        ("start", "Start from source"),
        ("related", "Related answers"),
    ],
    faqs=[
        ("Does it work with my existing security CLI items?", "If account is your Mac username and you know the service string, Retrieve can find it. Partial names list matches."),
        ("Swift version?", "Swift 6.1, macOS 14+, Package.swift in the repo."),
        ("Sandbox?", "No. A sandbox would hide items from security(1). That is a deliberate trade."),
        ("CI artifacts?", "Tests only. CI does not attach an .app. Unsigned CI zips are not a release."),
    ],
    body=[
        ("h2", "The developer reality", "pain"),
        ("p", "You have three tokens for one side project and a live key for a client preview. They live in a password manager, a sticky note, and a `.env` that is gitignored except for the time it was not. Keychain Access can hold them, but the UI is built for certificates and Wi-Fi. `security add-generic-password` works until you forget whether the service string had an underscore."),
        ("p", "You do not want another subscription. You do want the item to be the same one your deploy script can `find-generic-password`. You want to see a masked value, copy it, and have the pasteboard forget."),
        ("p", "Monday looks like this: a webhook signing secret for a local tunnel, a personal OpenAI key, a Stripe test key, and a GitHub token that can push to one repo. None of them belong in the same 1Password vault as your bank. All of them belong in a place `security` can print. Keychain Access can hold them, but you will click Kind, Label, Account, and Where every time. A menu extra with one Name field is the whole product."),
        ("p", "If you maintain a `direnv` setup, you still need a canonical store. direnv loads files. Files leak. Keep the live values in the Keychain and, if you must, have a private script call `find-generic-password` into the environment for that directory. ezkey does not replace direnv. It replaces the plaintext file direnv was about to read."),
        ("h2", "How ezkey helps", "how"),
        ("ul", [
            "Save and Retrieve from the menu bar. No Dock icon.",
            "Name is Keychain Access Name and Where, one field.",
            "Retrieve by substring, then pick. Secrets stay hidden until you choose.",
            "Copy clears in 30 seconds if unchanged.",
            "Same login.keychain-db as the CLI.",
        ]),
        ("p", "The source is https://github.com/edtadros/ezkey. Read `LoginKeychainStore.swift` if you do not trust marketing pages. Tests live in `Tests/EZKeyCoreTests` and use an `ezkey.test.` name prefix. CI runs `swift test` on macos-15. It does not attach an `.app`. If a random Actions artifact offers you a binary, do not grant it Keychain access."),
        ("h2", "What it will not do", "not"),
        ("p", "It will not rotate keys at OpenAI. It will not sync to a phone. It will not hide from a process running as you. It will not replace 1Password for your bank. It will not ship a notarized binary until someone runs `scripts/release.sh` with Developer ID. Those are not missing checkboxes. They are the product boundary. See [anti-cloud local keys](/for/local-api-keys/)."),
        ("h2", "Start from source", "start"),
        ("pre", "git clone https://github.com/edtadros/ezkey.git\ncd ezkey\n./scripts/build-and-run.sh"),
        ("p", "Requires macOS 14+ and Xcode command-line tools. Then follow [how to save API keys securely](/guides/how-to-save-api-keys-securely-on-mac/)."),
        ("p", "If you already have items from `security add-generic-password`, try Retrieve with part of the service string. If the list is empty, check Account in Keychain Access. ezkey only lists the logged-in Mac user. That is annoying if you used `-a` as a project name. It is also how the extra stays small. Rename or resave if you want the menu extra to see them."),
        ("h2", "Related answers", "related"),
        ("related", [
            ("/guides/security-add-generic-password/", "security add-generic-password", "Flag map to ezkey fields."),
            ("/compare/ezkey-vs-keychain-access/", "ezkey vs Keychain Access", "Same database."),
            ("/guides/best-way-to-store-api-keys-on-macos/", "Best way to store API keys on macOS", "Where a vault still wins."),
            ("/developers/", "Developers (site API)", "MCP and OpenAPI for this website, not for Keychain."),
        ]),
    ],
)

add(
    slug="for/local-api-keys",
    short="Local API keys",
    title="Store API keys locally on a Mac — ezkey.app",
    h1="Where should local API keys live on a Mac?",
    description="If an API key must not leave this Mac, put it in the login Keychain, not in a cloud password manager and not in a project .env. ezkey is a local extra for those items.",
    answer="If the rule is that the key must not leave this computer, the login Keychain is the local store that macOS already encrypts. Do not use iCloud-synced password apps as the canonical copy for that key. Do not use `.env`. ezkey.app writes generic passwords into login.keychain-db and nowhere else.",
    toc=[
        ("rule", "The local-only rule"),
        ("icloud", "Why iCloud Keychain is the wrong drawer"),
        ("practice", "Practice"),
        ("related", "Related answers"),
    ],
    faqs=[
        ("Can I back up login.keychain-db?", "Time Machine will copy the encrypted file. That is a backup of ciphertext plus your login password story. Treat the login password as the recovery."),
        ("What if I need the key on two Macs?", "Then it is not a local-only key. Use a vault with a sharing model you accept, or carry it yourself."),
        ("Does ezkey phone home?", "The app has no network calls. This website is static docs. Do not paste secrets into GitHub issues."),
        ("Is FileVault required?", "It is the disk-at-rest control. Use it. ezkey will still run without it; the threat model gets worse."),
    ],
    body=[
        ("h2", "The local-only rule", "rule"),
        ("p", "Some keys are more like house keys than like shared office badges. A personal OpenAI key that bills your card. A staging token for an app that is not supposed to exist yet. A webhook secret on a machine that never opens a ticket with a vendor. Those keys should not ride a sync channel you cannot see."),
        ("p", "Cloud password managers are good at the opposite job. They are designed to leave this Mac. If you put a “never leave” key there, you have redefined the job."),
        ("p", "Local-only is not the same as “I turned off Wi-Fi.” iCloud Drive can still ship a `.env` to another device. Screenshots still leave. The rule is: the canonical bits sit in login.keychain-db, the login password is the recovery, and no vendor account is in the path. If that recovery story scares you, you do not want a local-only key. You want a vault with a recovery mailbox. Say that out loud before you mix the two."),
        ("h2", "Why iCloud Keychain is the wrong drawer", "icloud"),
        ("p", "iCloud Keychain / Passwords is built to appear on your phone. Generic passwords in login.keychain-db do not automatically do that. ezkey uses the file-based login Keychain so `security` and Keychain Access see the same items. That is a compatibility choice and a locality choice. Read [how to save API keys securely](/guides/how-to-save-api-keys-securely-on-mac/) if you need the mechanics."),
        ("p", "Developers sometimes hear “use the Secure Enclave” and assume every Keychain item is hardware-bound. Generic passwords in the login file are not Secure Enclave keys. They are encrypted items in a file. FileVault protects the disk when the Mac is off. The login password protects the Keychain file. Touch ID on a different item class is a different product. ezkey does not pretend otherwise."),
        ("h2", "Practice", "practice"),
        ("ol", [
            "Name the key as if you will search for it in six months.",
            "Save it with ezkey or security(1) into login.keychain-db.",
            "Export into the environment only in the terminal that runs the client.",
            "Delete `.env` copies and zshrc exports of the raw value.",
            "Rotate anything that already escaped.",
        ]),
        ("p", "Build ezkey from [source](https://github.com/edtadros/ezkey) if the menu bar extra is useful. If it is not, the Keychain is still the right drawer."),
        ("p", "A local-only key still dies with the disk if you have no backup of login.keychain-db and you forget the login password. That is the trade. Encrypted backup of the Keychain file is your problem, not ezkey’s. Do not email yourself the secret as a “backup.” That email is a second canonical copy in a worse store."),
        ("h2", "Related answers", "related"),
        ("related", [
            ("/guides/best-way-to-store-api-keys-on-macos/", "Best way to store API keys on macOS", "Local vs team split."),
            ("/compare/macos-keychain-vs-1password-for-api-keys/", "Keychain vs 1Password", "Honesty section included."),
            ("/for/developers/", "For developers", "CLI compatibility."),
            ("/privacy/", "Privacy", "The app collects nothing."),
        ]),
    ],
)

add(
    slug="compare/macos-keychain-vs-1password-for-api-keys",
    short="Keychain vs 1Password",
    title="macOS Keychain vs 1Password for API keys — ezkey.app",
    h1="macOS Keychain vs 1Password for API keys",
    description="Use the login Keychain for keys that must stay on one Mac. Use 1Password when you need sharing, recovery, or a phone. ezkey is a local extra for the Keychain side.",
    answer="Use the macOS login Keychain when the API key should stay on this computer and you already live in Terminal. Use 1Password when another person, another device, or a recovery story matters more than staying local. ezkey.app only helps the Keychain side. 1Password is a better password manager. The Keychain is a better local drawer.",
    toc=[
        ("split", "The honest split"),
        ("table", "Side by side"),
        ("keychain-wins", "Where Keychain wins"),
        ("1p-wins", "Where 1Password still wins"),
        ("ezkey", "ezkey’s place"),
        ("related", "Related answers"),
    ],
    faqs=[
        ("Can I use both?", "Yes. Bank and shared logins in 1Password. Machine-local tokens in the login Keychain."),
        ("Does 1Password store items in the Keychain too?", "It uses platform APIs for its own unlock. That is not the same as your generic-password item named my-app-api-token."),
        ("Is Bitwarden the same comparison?", "Same shape: hosted vault vs local file. Details differ. The local-only rule does not."),
        ("Does ezkey compete with 1Password?", "No. If you need 1Password, you need 1Password."),
    ],
    body=[
        ("h2", "The honest split", "split"),
        ("p", "People type “best way to save keys” into a search box after a scare. Vendors answer with their brand. The useful answer is a split. Sharing and recovery are 1Password’s product. A file on this Mac that `security` can print is Apple’s login Keychain. Pretending either one is universal is how keys end up in the wrong drawer."),
        ("h2", "Side by side", "table"),
        ("table", ["", "login Keychain", "1Password"], [
            ["Where the bits live", "login.keychain-db on this Mac", "1Password’s vault, usually synced"],
            ["Account required", "Your Mac login", "A 1Password account"],
            ["CLI", "security(1), built in", "op CLI, extra install"],
            ["Menu bar for generic passwords", "Keychain Access, or ezkey", "1Password app"],
            ["Share with a teammate", "No", "Yes"],
            ["Phone", "Not this file", "Yes"],
            ["Price", "Included with macOS", "Subscription"],
        ]),
        ("h2", "Where Keychain wins", "keychain-wins"),
        ("p", "No extra account. No vendor outage. The same item your script already knows how to `find-generic-password`. Works offline because it is a file. ezkey and Keychain Access are just windows onto it. See [how to save API keys securely](/guides/how-to-save-api-keys-securely-on-mac/)."),
        ("h2", "Where 1Password still wins", "1p-wins"),
        ("ul", [
            "You forgot the Mac password and still need a travel login — recovery is their job, not login.keychain-db.",
            "A family member needs the Wi-Fi and the streaming password.",
            "Watchtower, sharing, document storage, browser fill.",
            "You want a company admin to revoke access without touching the laptop.",
        ]),
        ("p", "Those are real wins. A Keychain tutorial that pretends otherwise is selling you a smaller product. This page is not a 1Password hatchet job."),
        ("p", "Watchtower-style alerts, document storage, and browser fill are also 1Password’s job. The login Keychain will not tell you that a site password appeared in a dump. It will not fill a credit card on the web. If that is what you meant by “save keys,” you asked the wrong question. This comparison is only about API tokens a developer copies into a terminal."),
        ("h2", "ezkey’s place", "ezkey"),
        ("p", "ezkey does not implement a vault. It does not sync. It is a menu extra for generic passwords that already belong in the login Keychain. Build it from source or skip it and use `security`. Either way the comparison above still holds."),
        ("h2", "Related answers", "related"),
        ("related", [
            ("/guides/best-way-to-store-api-keys-on-macos/", "Best way to store API keys on macOS", "More options than these two."),
            ("/compare/ezkey-vs-keychain-access/", "ezkey vs Keychain Access", "Same Keychain, different UI."),
            ("/for/local-api-keys/", "Local API keys", "When sync is a bug."),
            ("/for/developers/", "For developers", "CLI round-trip."),
        ]),
    ],
)

add(
    slug="compare/ezkey-vs-keychain-access",
    short="ezkey vs Keychain Access",
    title="ezkey vs Keychain Access — ezkey.app",
    h1="ezkey vs Keychain Access",
    description="Both use the macOS login Keychain. Keychain Access is the system UI. ezkey is a menu bar extra for generic passwords with substring retrieve. Same file, different job.",
    answer="Keychain Access is Apple’s app for every kind of Keychain item. ezkey.app is a tiny extra for generic passwords: save, retrieve by name or substring, reveal, copy. They can see the same login.keychain-db items when Name/Where and Account match. Use Access for certificates and ACLs. Use ezkey if you live on one Name field in the menu bar.",
    toc=[
        ("same", "Same database"),
        ("diff", "Different job"),
        ("when-access", "When Keychain Access is better"),
        ("when-ezkey", "When ezkey is better"),
        ("related", "Related answers"),
    ],
    faqs=[
        ("Will an item I create in Access show up in ezkey?", "If it is a generic password, account is your Mac user, and you search the Name/Where string, yes. Other item classes will not."),
        ("Can ezkey edit Access Control lists?", "No. Use Keychain Access."),
        ("Does ezkey replace security(1)?", "No. It is compatible with add/find-generic-password for the fields it uses."),
        ("Why isn’t ezkey sandboxed?", "A sandbox would store items where the security CLI cannot see them. Compatibility with CLI items is the point."),
    ],
    body=[
        ("h2", "Same database", "same"),
        ("p", "ezkey opens `~/Library/Keychains/login.keychain-db` through Security.framework. Keychain Access shows that file as the login keychain. If you save `my-app-api-token` in ezkey, Access should list it with Name and Where set to that string and Account set to your user. The [glossary](/glossary/) is the field map."),
        ("h2", "Different job", "diff"),
        ("table", ["", "Keychain Access", "ezkey"], [
            ["Scope", "Passwords, keys, certs, notes", "Generic passwords only"],
            ["Find", "Search box, lots of columns", "Exact Name, then substring list"],
            ["Always in the menu bar", "No", "Yes"],
            ["Clipboard timer", "No", "30 seconds if unchanged"],
            ["ACL editor", "Yes", "No"],
            ["Source", "Closed, from Apple", "MIT, github.com/edtadros/ezkey"],
        ]),
        ("h2", "When Keychain Access is better", "when-access"),
        ("p", "Certificates, code signing identities, looking at Access Control, fixing a stuck Always Allow, inspecting iCloud items. ezkey will not grow into that. If you need those tools, open Access. That is not a failure of ezkey. It is the division of labor."),
        ("p", "Access is also the right place when an item will not delete, when two items share a confusing Where, or when you need to see which apps are trusted. ezkey will not show ACL entries. If Retrieve fails with a prompt you do not understand, open Access, find the item, and read Access Control. Then decide whether Always Allow is something you want to give a binary you compiled."),
        ("h2", "When ezkey is better", "when-ezkey"),
        ("p", "You save and retrieve a handful of API tokens every week. You know the Name. You do not want to hunt Kind columns. You want a masked field and a copy button. You want `security` to keep working. Then a menu extra that only does generic passwords is calmer than Access. Build it yourself. See [for developers](/for/developers/)."),
        ("p", "ezkey will not import a CSV of passwords. It will not show your Safari logins. If Access is open because you are hunting a Wi-Fi password, stay there. If Access is open because you cannot remember the `-s` string for a generic password you created last month, the extra’s substring list is the feature."),
        ("h2", "Related answers", "related"),
        ("related", [
            ("/guides/security-add-generic-password/", "security add-generic-password", "The CLI both of you sit on."),
            ("/guides/how-to-save-api-keys-securely-on-mac/", "Save API keys securely", "The actual procedure."),
            ("/compare/macos-keychain-vs-1password-for-api-keys/", "Keychain vs 1Password", "Different layer."),
            ("/security/", "Security", "Prompts and Always Allow."),
        ]),
    ],
)


HUB_QUESTIONS = [
    ("/guides/how-to-save-api-keys-securely-on-mac/", "How can I save API keys securely on a Mac?", "Login Keychain, not .env."),
    ("/guides/best-way-to-store-api-keys-on-macos/", "What is the best way to store API keys on macOS?", "Local Keychain vs a team vault."),
    ("/guides/is-it-safe-to-put-api-keys-in-dotenv/", "Is it safe to put API keys in .env files?", "Plaintext. gitignore is not encryption."),
    ("/guides/how-to-store-openai-api-key-on-mac/", "How do I store an OpenAI API key on a Mac?", "Do not append it to ~/.zshrc."),
    ("/guides/security-add-generic-password/", "How do I use security add-generic-password?", "Prompt for -w. Match -a and -s."),
    ("/for/developers/", "Is there a Keychain GUI for developers?", "Menu extra, same file as the CLI."),
    ("/for/local-api-keys/", "Where should local API keys live?", "login.keychain-db if they must not leave."),
    ("/compare/macos-keychain-vs-1password-for-api-keys/", "Keychain vs 1Password for API keys?", "Local drawer vs shared vault."),
    ("/compare/ezkey-vs-keychain-access/", "ezkey vs Keychain Access?", "Same database, smaller job."),
]


def render_hub() -> tuple[str, str]:
    rows = "".join(
        f'<div class="row"><a href="{html.escape(href, quote=True)}">{inline_md(q)}<small>{inline_md(b)}</small></a></div>'
        for href, q, b in HUB_QUESTIONS
    )
    md_items = "\n".join(f"- [{q}]({ORIGIN}{href}): {b}" for href, q, b in HUB_QUESTIONS)
    html_page = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Guides — how to save keys on a Mac — ezkey.app</title>
  <meta name="description" content="Direct answers: how to save API keys securely on a Mac, whether .env is safe, security CLI flags, and Keychain vs 1Password.">
  <meta name="is-agentic-site-type" content="content">
  <meta property="og:title" content="Guides — ezkey.app">
  <meta property="og:description" content="Question-led answers for storing API keys on macOS.">
  <meta property="og:type" content="website">
  <meta property="og:image" content="{ORIGIN}/og.png">
  <meta property="og:url" content="{ORIGIN}/guides/">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large">
  <link rel="canonical" href="{ORIGIN}/guides/">
  <link rel="describedby" href="{ORIGIN}/llms.txt" type="text/plain">
  <link rel="alternate" type="text/markdown" href="{ORIGIN}/guides.md">
  <link rel="ard" href="{ORIGIN}/.well-known/ard.json">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="/styles.css">
  <script src="/webmcp.js" defer></script>
</head>
<body>
  <a class="skip" href="#main">Skip to content</a>
  <header class="top">
    <a class="mark" href="/">ezkey</a>
{NAV}
  </header>
  <main id="main" class="legal">
    <h1>Guides</h1>
    <div class="answer"><p>Short answers to the questions people actually type: how to save API keys securely on a Mac, whether <code>.env</code> is safe, and when 1Password is the better tool. ezkey.app is a local menu extra for the login Keychain. These pages are the public answers.</p></div>
    <section class="group q-list">
      <h2>Questions</h2>
      {rows}
    </section>
    <p>Build from source: <a href="https://github.com/edtadros/ezkey">github.com/edtadros/ezkey</a>. MIT, as-is.</p>
  </main>
{FOOT}
</body>
</html>
"""
    md = f"""---
title: Guides — how to save keys on a Mac — ezkey.app
description: Direct answers for storing API keys on macOS with the login Keychain.
---

# Guides

Short answers to the questions people actually type. ezkey.app is a local menu extra for the login Keychain.

{md_items}

Build from source: https://github.com/edtadros/ezkey
"""
    return html_page, md


def write_page(rel: str, html_doc: str, md_doc: str) -> None:
    if rel == "guides":
        html_path = SITE / "guides" / "index.html"
        md_path = SITE / "guides.md"
    else:
        html_path = SITE / rel / "index.html"
        md_path = SITE / f"{rel}.md"
    html_path.parent.mkdir(parents=True, exist_ok=True)
    html_path.write_text(html_doc)
    md_path.parent.mkdir(parents=True, exist_ok=True)
    md_path.write_text(md_doc)
    print("wrote", html_path.relative_to(SITE), md_path.relative_to(SITE))


def main() -> None:
    hub_html, hub_md = render_hub()
    write_page("guides", hub_html, hub_md)
    slugs = ["guides"]
    for page in PAGES:
        write_page(page["slug"], render_html(page), render_md(page))
        slugs.append(page["slug"])
    (SITE / "guides" / "slugs.txt").write_text("\n".join(slugs) + "\n")


if __name__ == "__main__":
    main()
