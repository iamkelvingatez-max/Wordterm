#!/usr/bin/env bash
# COPY → word_oc.sh  (OVERWRITE)
# Usage:
#   ./word_oc.sh kiosk
#   ./word_oc.sh window
#
# Env:
#   WORDOC_DIR="$HOME/.cache/wordoc"          (optional)
#   WORDOC_TITLE="Document1 - Word"          (optional)
#   WORDOC_SCALE="1"                         (optional; chrome device scale factor: 1, 1.25, 1.5)
#   WORDOC_TIMEOUT="300"                     (optional; seconds per command)

set -euo pipefail

MODE="${1:-window}"
WORDOC_DIR="${WORDOC_DIR:-$HOME/.cache/wordoc}"
WORDOC_TITLE="${WORDOC_TITLE:-Document1 - Word}"
WORDOC_SCALE="${WORDOC_SCALE:-1}"
WORDOC_TIMEOUT="${WORDOC_TIMEOUT:-300}"

mkdir -p "$WORDOC_DIR"
HTML="$WORDOC_DIR/word-like.html"
SERVER="$WORDOC_DIR/wordoc_server.py"
STATE="$WORDOC_DIR/state.json"
PROFILE="$WORDOC_DIR/chrome-profile"

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found."; exit 1; }

# ---------------- HTML (Word-style UI + Terminal modal) ----------------
cat > "$HTML" <<'HTML_EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>__WORDOC_TITLE__</title>
  <style>
    :root{
      --h-title: 44px;
      --h-tabs: 32px;
      --h-ribbon: 110px;
      --h-status: 28px;

      --chrome: #eef3f7;
      --ribbon: #ffffff;
      --canvas: #e9eef3;
      --text: #1f1f1f;
      --muted: #5f5f5f;
      --muted2:#7a7a7a;
      --line: rgba(0,0,0,.10);
      --line2: rgba(0,0,0,.16);
      --line3: rgba(0,0,0,.12);
      --blue: #185abd;
      --accent: #2b579a;
      --purple: #7a3fb1;
      --danger: #d13438;
      --yellow: #f5d000;
      --font: "Segoe UI Variable","Segoe UI",system-ui,-apple-system,Arial,sans-serif;

      --page-w: 816px;
      --page-h: 1056px;
      --shadow: 0 10px 24px rgba(0,0,0,.18);
    }

    *{ box-sizing:border-box; }
    html,body{ height:100%; }
    body{
      margin:0;
      font-family: var(--font);
      color: var(--text);
      background: var(--canvas);
      -webkit-font-smoothing: antialiased;
      text-rendering: geometricPrecision;
      overflow:hidden; /* no big scrollbar */
    }

    .app{
      height:100%;
      display:grid;
      grid-template-rows: var(--h-title) var(--h-tabs) var(--h-ribbon) 1fr var(--h-status);
      overflow:hidden;
    }

    /* ---------- TITLEBAR ---------- */
    .titlebar{
      background: var(--chrome);
      border-bottom: 1px solid var(--line);
      display:flex;
      align-items:center;
      gap:10px;
      padding: 0 10px;
      user-select:none;
    }

    .left-title{
      display:flex;
      align-items:center;
      gap:10px;
      min-width: 430px;
    }

    .word-icon{
      width: 22px;
      height: 22px;
      border-radius: 3px;
      background: var(--accent);
      display:grid;
      place-items:center;
      color:#fff;
      font-weight:700;
      font-size: 12px;
      letter-spacing:.2px;
    }

    .autosave{
      display:flex;
      align-items:center;
      gap:8px;
      font-size: 12px;
      color: var(--text);
    }

    .toggle{
      width: 40px; height: 18px;
      border-radius:999px;
      border: 1px solid var(--line2);
      background: #fff;
      position:relative;
      box-shadow: 0 1px 0 rgba(0,0,0,.03) inset;
    }
    .toggle::after{
      content:"";
      position:absolute;
      top:2px; left:2px;
      width: 14px; height: 14px;
      border-radius:999px;
      background:#c9c9c9;
      box-shadow: 0 1px 2px rgba(0,0,0,.18);
    }
    .toggle-off{ font-size: 12px; color: var(--muted2); }

    .qa{ display:flex; align-items:center; gap:6px; margin-left: 2px; }

    .qbtn{
      width: 24px; height: 24px;
      border-radius: 6px;
      display:grid;
      place-items:center;
      border:1px solid transparent;
      background: transparent;
      cursor:pointer;
      color:#4a4a4a;
    }
    .qbtn:hover{ background: rgba(0,0,0,.04); border-color: var(--line); }

    .docname{
      font-size: 12.5px;
      color:#2f2f2f;
      margin-left: 4px;
      white-space: nowrap;
    }

    .searchwrap{ flex:1; display:flex; justify-content:center; padding: 0 10px; min-width: 220px; }
    .search{
      width: 520px;
      max-width: 52vw;
      height: 30px;
      border: 1px solid var(--line2);
      border-radius: 3px;
      background:#fff;
      display:flex;
      align-items:center;
      gap:8px;
      padding: 0 10px;
      color: var(--muted2);
      font-size: 12.5px;
      box-shadow: 0 1px 0 rgba(0,0,0,.02) inset;
    }
    .search input{
      border:none; outline:none; width:100%;
      font: inherit;
      background: transparent;
      color: var(--text);
    }

    .right-title{
      display:flex;
      align-items:center;
      gap:10px;
      min-width: 360px;
      justify-content:flex-end;
    }

    .avatar{
      width: 22px; height: 22px;
      border-radius:999px;
      background:#5a78ff;
      color:#fff;
      display:grid;
      place-items:center;
      font-size: 11px;
      font-weight:700;
    }

    .winbtns{ display:flex; align-items:center; gap:2px; margin-left: 2px; }
    .win{
      width: 34px;
      height: 24px;
      border-radius: 6px;
      border:1px solid transparent;
      background:transparent;
      display:grid;
      place-items:center;
      cursor:pointer;
      color:#3f3f3f;
    }
    .win:hover{ background: rgba(0,0,0,.04); border-color: var(--line); }

    .status-bubble{
      width: 24px; height: 24px;
      border-radius: 999px;
      border: 1px solid var(--line2);
      background:#fff;
      display:grid;
      place-items:center;
      color:#1a8f4a;
      box-shadow: 0 1px 0 rgba(0,0,0,.03) inset;
    }

    .share{
      height: 28px;
      padding: 0 10px;
      border:none;
      border-radius: 4px;
      background: var(--blue);
      color:#fff;
      font-weight: 600;
      font-size: 12.5px;
      display:flex;
      align-items:center;
      gap: 6px;
      cursor:pointer;
      box-shadow: 0 1px 0 rgba(0,0,0,.10) inset;
    }
    .share:hover{ filter: brightness(.96); }

    /* ---------- TABS ---------- */
    .tabsbar{
      background: var(--chrome);
      border-bottom: 1px solid var(--line);
      display:flex;
      align-items:flex-end;
      gap: 14px;
      padding: 0 10px;
      user-select:none;
      overflow:hidden;
    }
    .tab{
      appearance:none;
      border:none;
      background: transparent;
      padding: 8px 0 7px;
      font-size: 12.8px;
      color:#333;
      cursor:pointer;
      position:relative;
      line-height:1;
      white-space:nowrap;
    }
    .tab.active{ font-weight: 600; color:#111; }
    .tab.active::after{
      content:"";
      position:absolute;
      left:0; right:0; bottom:-1px;
      height: 3px;
      background: var(--blue);
      border-radius: 2px 2px 0 0;
    }

    /* ---------- RIBBON ---------- */
    .ribbon{
      background: var(--ribbon);
      border-bottom: 1px solid var(--line2);
      display:flex;
      align-items:stretch;
      padding: 6px 10px 8px;
      gap: 10px;
      user-select:none;

      overflow-x:auto;
      overflow-y:hidden;
      scrollbar-width:none;
    }
    .ribbon::-webkit-scrollbar{ height:0; }

    .group{
      position:relative;
      padding: 2px 12px 18px;
      display:flex;
      flex-direction:column;
      gap: 8px;
      min-width: 170px;
      flex: 0 0 auto;
    }
    .group::after{
      content:"";
      position:absolute;
      top: 6px;
      bottom: 8px;
      right: -6px;
      width: 1px;
      background: var(--line3);
    }
    .group:last-child::after{ display:none; }

    .gtitle{
      position:absolute;
      left:0; right:0;
      bottom: 2px;
      font-size: 11px;
      color: var(--muted);
      text-align:center;
    }
    .launcher{
      position:absolute;
      right: 4px;
      bottom: 2px;
      width: 16px;
      height: 16px;
      border:1px solid transparent;
      border-radius: 3px;
      display:grid;
      place-items:center;
      color: #7a7a7a;
      cursor:pointer;
    }
    .launcher:hover{ border-color: var(--line); background: rgba(0,0,0,.03); }

    .row{ display:flex; align-items:flex-start; gap: 8px; }
    .col{ display:flex; flex-direction:column; gap: 6px; }

    .btn{
      border: 1px solid transparent;
      background: transparent;
      border-radius: 6px;
      padding: 5px 6px;
      display:flex;
      align-items:center;
      gap: 6px;
      font-size: 12.2px;
      color:#2f2f2f;
      cursor:pointer;
      line-height:1.05;
    }
    .btn:hover{ background: rgba(0,0,0,.04); border-color: var(--line); }
    .btn:active{ transform: translateY(.5px); }

    .btn.disabled{ opacity:.42; cursor:default; filter: grayscale(1); }
    .btn.disabled:hover{ background: transparent; border-color: transparent; }

    .btn.big{
      width: 74px;
      height: 66px;
      flex-direction:column;
      justify-content:center;
      align-items:center;
      text-align:center;
      gap: 4px;
      border: 1px solid var(--line);
      background: linear-gradient(#ffffff, #fbfcfe);
      box-shadow: 0 1px 0 rgba(0,0,0,.06);
    }
    .btn.big .lbl{ font-size: 12px; }
    .btn.big .sub{ font-size: 11px; color: var(--muted2); margin-top: -2px; }

    .iconbtn{
      width: 28px;
      height: 26px;
      border-radius: 6px;
      border: 1px solid transparent;
      background: transparent;
      display:grid;
      place-items:center;
      cursor:pointer;
      color:#2f2f2f;
    }
    .iconbtn:hover{ background: rgba(0,0,0,.04); border-color: var(--line); }
    .iconbtn.disabled{ opacity:.42; cursor:default; filter: grayscale(1); }
    .iconbtn.disabled:hover{ background:transparent; border-color:transparent; }

    .drop{
      height: 24px;
      border: 1px solid var(--line2);
      border-radius: 4px;
      background: #fff;
      padding: 0 8px;
      display:flex;
      align-items:center;
      justify-content:space-between;
      gap: 8px;
      font-size: 12px;
      color:#2f2f2f;
      min-width: 140px;
      box-shadow: 0 1px 0 rgba(0,0,0,.03) inset;
    }
    .drop.small{ min-width: 52px; }
    .caret{ color: var(--muted2); font-size: 12px; }
    .vsep{ width:1px; align-self:stretch; background: var(--line); margin: 0 4px; }

    .ico{ width: 16px; height: 16px; display:inline-block; color:#2f2f2f; }
    .ico.big{ width: 24px; height: 24px; }
    svg{ display:block; shape-rendering: geometricPrecision; }
    .stroke{
      stroke: currentColor;
      stroke-width: 1.4;
      stroke-linecap: round;
      stroke-linejoin: round;
      vector-effect: non-scaling-stroke;
      fill: none;
    }

    /* ---------- DOC AREA (NO RULERS/GRAPH) ---------- */
    .editor{
      background: var(--canvas);
      overflow-y:auto;
      overflow-x:hidden;
      padding: 18px 0 30px;
    }
    .page{
      width: var(--page-w);
      min-height: var(--page-h);
      margin: 0 auto;
      background: #fff;
      border: 1px solid var(--line);
      box-shadow: var(--shadow);
      outline:none;
      padding: 72px;
      border-radius: 2px;
    }
    .page:focus{
      border-color: rgba(43,87,154,.35);
      box-shadow: 0 0 0 4px rgba(43,87,154,.10), var(--shadow);
    }

    /* ---------- STATUS ---------- */
    .status{
      background:#fff;
      border-top: 1px solid var(--line);
      display:flex;
      align-items:center;
      justify-content:space-between;
      padding: 0 10px;
      font-size: 11.5px;
      color:#3a3a3a;
      user-select:none;
    }
    .status .left,.status .right{ display:flex; align-items:center; gap: 12px; }

    .statusbtn{
      height: 22px;
      padding: 0 8px;
      border-radius: 5px;
      border: 1px solid transparent;
      background: transparent;
      display:flex;
      align-items:center;
      gap:6px;
      cursor:pointer;
      color:#3a3a3a;
    }
    .statusbtn:hover{ background: rgba(0,0,0,.04); border-color: var(--line); }

    .zoom{ display:flex; align-items:center; gap:8px; color: var(--muted2); }
    .slider{
      width: 110px;
      height: 4px;
      border-radius:999px;
      background: rgba(0,0,0,.14);
      position:relative;
    }
    .knob{
      position:absolute;
      top:50%;
      transform: translate(-50%,-50%);
      left: 78%;
      width: 10px;
      height: 10px;
      border-radius:999px;
      background:#fff;
      border: 1px solid rgba(0,0,0,.24);
      box-shadow: 0 1px 2px rgba(0,0,0,.18);
    }

    /* ---------- TERMINAL MODAL ---------- */
    .modalback{
      position: fixed;
      inset: 0;
      background: rgba(0,0,0,.22);
      display:none;
      align-items:center;
      justify-content:center;
      z-index: 9999;
    }
    .modal{
      width: min(980px, 92vw);
      height: min(560px, 82vh);
      background:#fff;
      border: 1px solid rgba(0,0,0,.18);
      box-shadow: 0 18px 50px rgba(0,0,0,.28);
      border-radius: 10px;
      overflow:hidden;
      display:grid;
      grid-template-rows: 42px 1fr 54px;
    }
    .modalhead{
      background: var(--chrome);
      border-bottom: 1px solid var(--line);
      display:flex;
      align-items:center;
      justify-content:space-between;
      padding: 0 10px;
      user-select:none;
    }
    .modaltitle{
      display:flex; align-items:center; gap:8px;
      font-size: 12.5px;
      color:#2f2f2f;
      font-weight: 600;
    }
    .pill{
      font-size: 11px;
      padding: 2px 8px;
      border-radius: 999px;
      border: 1px solid var(--line2);
      background: rgba(255,255,255,.7);
      color:#444;
      font-weight: 500;
    }
    .closebtn{
      width: 34px; height: 28px;
      border-radius: 8px;
      border: 1px solid transparent;
      background: transparent;
      cursor:pointer;
      display:grid;
      place-items:center;
      color:#3f3f3f;
    }
    .closebtn:hover{ background: rgba(0,0,0,.05); border-color: var(--line); }

    .terminal{
      background: #0f1115;
      color: #e8e8e8;
      padding: 10px 12px;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
      font-size: 12.5px;
      overflow:auto;
      white-space: pre-wrap;
      line-height: 1.35;
    }
    .line-err{ color: #ff6b6b; }
    .line-ok{ color: #e8e8e8; }
    .line-dim{ color: #a0a0a0; }

    .modalfoot{
      border-top: 1px solid var(--line);
      background:#fff;
      display:flex;
      align-items:center;
      gap: 10px;
      padding: 8px 10px;
    }
    .cmd{
      flex:1;
      height: 36px;
      border: 1px solid var(--line2);
      border-radius: 8px;
      padding: 0 10px;
      font: inherit;
      outline:none;
    }
    .runbtn{
      height: 36px;
      padding: 0 14px;
      border:none;
      border-radius: 8px;
      background: var(--blue);
      color:#fff;
      font-weight: 600;
      cursor:pointer;
    }
    .runbtn:disabled{ opacity:.6; cursor:default; }
    .ghost{
      height: 36px;
      padding: 0 12px;
      border-radius: 8px;
      border: 1px solid var(--line2);
      background:#fff;
      cursor:pointer;
    }
  </style>
</head>

<body>
  <div class="app">

    <header class="titlebar">
      <div class="left-title">
        <div class="word-icon">W</div>
        <div class="autosave">
          <span>AutoSave</span>
          <span class="toggle" aria-hidden="true"></span>
          <span class="toggle-off">Off</span>
        </div>

        <div class="qa" aria-label="Quick Access Toolbar">
          <button class="qbtn" title="Save" aria-label="Save" style="color:var(--purple)">
            <span class="ico">
              <svg viewBox="0 0 24 24"><path class="stroke" d="M5 4h12l2 2v14H5V4Z"/><path class="stroke" d="M8 4v6h8V4"/><path class="stroke" d="M8 20v-6h8v6"/></svg>
            </span>
          </button>
          <button class="qbtn" title="Undo" aria-label="Undo">
            <span class="ico">
              <svg viewBox="0 0 24 24"><path class="stroke" d="M9 7H5v4"/><path class="stroke" d="M5 11c2-4 7-6 11-3 2 2 3 6 1 9"/></svg>
            </span>
          </button>
          <button class="qbtn" title="Redo" aria-label="Redo">
            <span class="ico">
              <svg viewBox="0 0 24 24"><path class="stroke" d="M15 7h4v4"/><path class="stroke" d="M19 11c-2-4-7-6-11-3-2 2-3 6-1 9"/></svg>
            </span>
          </button>
          <button class="qbtn" title="Quick Access options" aria-label="Quick Access options">
            <span class="ico">
              <svg viewBox="0 0 24 24"><path class="stroke" d="M8 10l4 4 4-4"/></svg>
            </span>
          </button>
        </div>

        <div class="docname">__WORDOC_TITLE__</div>
      </div>

      <div class="searchwrap">
        <div class="search" role="search">
          <span class="ico" aria-hidden="true">
            <svg viewBox="0 0 24 24"><path class="stroke" d="M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z"/><path class="stroke" d="M16.5 16.5 21 21"/></svg>
          </span>
          <input aria-label="Search" placeholder="Search" />
        </div>
      </div>

      <div class="right-title">
        <div class="avatar" title="KG">KG</div>

        <div class="winbtns" aria-label="Window controls">
          <button class="win" title="Minimize" aria-label="Minimize">
            <span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M6 12h12"/></svg></span>
          </button>
          <button class="win" title="Maximize" aria-label="Maximize">
            <span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M7 7h10v10H7V7Z"/></svg></span>
          </button>
          <button class="win" title="Close" aria-label="Close">
            <span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M7 7l10 10M17 7 7 17"/></svg></span>
          </button>
        </div>

        <div class="status-bubble" title="Status">
          <span class="ico" aria-hidden="true" style="width:14px;height:14px;">
            <svg viewBox="0 0 24 24"><path class="stroke" d="M6 12l4 4 8-9"/></svg>
          </span>
        </div>

        <button class="share" title="Share">
          <span class="ico" aria-hidden="true" style="color:#fff">
            <svg viewBox="0 0 24 24"><path class="stroke" d="M12 5v10"/><path class="stroke" d="M8 8l4-4 4 4"/><path class="stroke" d="M6 14v5h12v-5"/></svg>
          </span>
          Share <span style="opacity:.9">▾</span>
        </button>
      </div>
    </header>

    <nav class="tabsbar" aria-label="Ribbon tabs">
      <button class="tab">File</button>
      <button class="tab active">Home</button>
      <button class="tab">Insert</button>
      <button class="tab">Design</button>
      <button class="tab">Layout</button>
      <button class="tab">References</button>
      <button class="tab">Mailings</button>
      <button class="tab">Review</button>
      <button class="tab">View</button>
      <button class="tab">Developer</button>
      <button class="tab">Help</button>
      <button class="tab">Acrobat</button>
    </nav>

    <section class="ribbon" aria-label="Ribbon">
      <div class="group" style="min-width:160px">
        <div class="row">
          <button class="btn big" title="Paste" aria-label="Paste">
            <span class="ico big" aria-hidden="true">
              <svg viewBox="0 0 24 24">
                <path class="stroke" d="M8 4h8v3H8V4Z"/>
                <path class="stroke" d="M7 6H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-1"/>
                <path class="stroke" d="M9 12h6M9 15h6M9 18h6"/>
              </svg>
            </span>
            <span class="lbl">Paste</span>
            <span class="sub">▾</span>
          </button>

          <div class="col" style="padding-top:4px">
            <button class="iconbtn disabled" title="Cut" aria-label="Cut">
              <span class="ico" aria-hidden="true">
                <svg viewBox="0 0 24 24">
                  <path class="stroke" d="M9 9 21 21"/>
                  <path class="stroke" d="M21 3 9 15"/>
                  <path class="stroke" d="M7 7a2 2 0 1 1 0 4 2 2 0 0 1 0-4Z"/>
                  <path class="stroke" d="M7 13a2 2 0 1 1 0 4 2 2 0 0 1 0-4Z"/>
                </svg>
              </span>
            </button>
            <button class="iconbtn disabled" title="Copy" aria-label="Copy">
              <span class="ico" aria-hidden="true">
                <svg viewBox="0 0 24 24">
                  <path class="stroke" d="M9 9h10v10H9V9Z"/>
                  <path class="stroke" d="M5 15H4V5h10v1"/>
                </svg>
              </span>
            </button>
            <button class="iconbtn disabled" title="Format Painter" aria-label="Format Painter">
              <span class="ico" aria-hidden="true">
                <svg viewBox="0 0 24 24">
                  <path class="stroke" d="M7 7h10v4H7V7Z"/>
                  <path class="stroke" d="M9 11v8"/>
                  <path class="stroke" d="M9 19h6"/>
                </svg>
              </span>
            </button>
          </div>
        </div>
        <div class="gtitle">Clipboard</div>
        <button class="launcher" title="Clipboard options" aria-label="Clipboard options">
          <span class="ico" aria-hidden="true" style="width:12px;height:12px;">
            <svg viewBox="0 0 24 24"><path class="stroke" d="M8 8h8M8 12h8M8 16h8"/><path class="stroke" d="M16 20l4-4"/><path class="stroke" d="M14 20h6v-6"/></svg>
          </span>
        </button>
      </div>

      <div class="group" style="min-width:300px;">
        <div class="col" style="gap:8px;">
          <div class="row" style="gap:6px;">
            <div class="drop"><span>Aptos (Body)</span><span class="caret">▾</span></div>
            <div class="drop small"><span>11</span><span class="caret">▾</span></div>
            <button class="btn" title="Increase Font Size"><span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M12 6v12"/><path class="stroke" d="M6 12h12"/></svg></span></button>
            <button class="btn" title="Decrease Font Size"><span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M6 12h12"/></svg></span></button>
          </div>

          <div class="row" style="gap:4px; flex-wrap:wrap;">
            <button class="btn" title="Bold"><span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M8 5h6a4 4 0 0 1 0 8H8V5Z"/><path class="stroke" d="M8 13h7a4 4 0 0 1 0 8H8v-8Z"/></svg></span></button>
            <button class="btn" title="Italic"><span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M10 5h8M6 19h8M14 5l-4 14"/></svg></span></button>
            <button class="btn" title="Underline"><span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M8 5v7a4 4 0 0 0 8 0V5"/><path class="stroke" d="M6 19h12"/></svg></span></button>
            <div class="vsep"></div>
            <button class="btn" title="Text Highlight Color">
              <span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M7 14l7-7 3 3-7 7H7v-3Z"/><path class="stroke" d="M5 19h14"/><rect x="6" y="19.5" width="12" height="2" rx="1" fill="var(--yellow)"></rect></svg></span>
            </button>
            <button class="btn" title="Font Color">
              <span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M9 16l3-10 3 10"/><path class="stroke" d="M8 18h8"/><path d="M7 21h10" stroke="var(--danger)" stroke-width="2.2" stroke-linecap="round"/></svg></span>
            </button>
          </div>
        </div>
        <div class="gtitle">Font</div>
        <button class="launcher" title="Font options" aria-label="Font options">
          <span class="ico" aria-hidden="true" style="width:12px;height:12px;">
            <svg viewBox="0 0 24 24"><path class="stroke" d="M8 8h8M8 12h8M8 16h8"/><path class="stroke" d="M16 20l4-4"/><path class="stroke" d="M14 20h6v-6"/></svg>
          </span>
        </button>
      </div>
    </section>

    <section class="editor" aria-label="Document area">
      <div class="page" contenteditable="true" spellcheck="true" aria-label="Document page">
        <p style="margin:0; color:#6b6b6b;">(Click and type…)</p>
      </div>
    </section>

    <footer class="status">
      <div class="left">
        <div>Page 1 of 1</div>
        <div>0 words</div>
        <div style="display:flex;align-items:center;gap:6px;">
          <span class="ico" aria-hidden="true"><svg viewBox="0 0 24 24"><path class="stroke" d="M12 4a2 2 0 1 0 0 4 2 2 0 0 0 0-4Z"/><path class="stroke" d="M6 9h12"/><path class="stroke" d="M10 9v11"/><path class="stroke" d="M14 9v11"/></svg></span>
          Accessibility: Good to go
        </div>
      </div>
      <div class="right">
        <button class="statusbtn" id="openTerminal" title="Open Terminal (Ctrl+`)">
          <span class="ico" aria-hidden="true">
            <svg viewBox="0 0 24 24"><path class="stroke" d="M7 8l4 4-4 4"/><path class="stroke" d="M12 16h5"/></svg>
          </span>
          Terminal
        </button>
        <div class="zoom">
          <span>−</span>
          <div class="slider" aria-hidden="true"><div class="knob"></div></div>
          <span>+</span>
          <div style="color:#3a3a3a;">100%</div>
        </div>
      </div>
    </footer>

  </div>

  <!-- Terminal Modal -->
  <div class="modalback" id="modalBack">
    <div class="modal" role="dialog" aria-modal="true" aria-label="Terminal">
      <div class="modalhead">
        <div class="modaltitle">
          Terminal
          <span class="pill" id="cwdPill">cwd: …</span>
          <span class="pill" id="codePill">exit: …</span>
        </div>
        <button class="closebtn" id="closeTerminal" title="Close">
          <span class="ico"><svg viewBox="0 0 24 24"><path class="stroke" d="M7 7l10 10M17 7 7 17"/></svg></span>
        </button>
      </div>

      <div class="terminal" id="termOut"></div>

      <div class="modalfoot">
        <input class="cmd" id="cmd" placeholder="Type a command…  (examples: ls, pwd, cd /, cat file.txt)" />
        <button class="ghost" id="clearBtn" title="Clear Output">Clear</button>
        <button class="runbtn" id="runBtn">Run</button>
      </div>
    </div>
  </div>

  <script>
    const modalBack = document.getElementById('modalBack');
    const openTerminal = document.getElementById('openTerminal');
    const closeTerminal = document.getElementById('closeTerminal');
    const termOut = document.getElementById('termOut');
    const cmd = document.getElementById('cmd');
    const runBtn = document.getElementById('runBtn');
    const clearBtn = document.getElementById('clearBtn');
    const cwdPill = document.getElementById('cwdPill');
    const codePill = document.getElementById('codePill');

    function showTerm(){ modalBack.style.display = 'flex'; setTimeout(()=>cmd.focus(), 0); }
    function hideTerm(){ modalBack.style.display = 'none'; }

    function appendLine(text, cls='line-ok'){
      const div = document.createElement('div');
      div.className = cls;
      div.textContent = text;
      termOut.appendChild(div);
      termOut.scrollTop = termOut.scrollHeight;
    }

    async function runCommand(){
      const value = cmd.value.trim();
      if(!value) return;
      runBtn.disabled = true;

      appendLine(`$ ${value}`, 'line-dim');
      cmd.value = '';

      try{
        const res = await fetch('/api/run', {
          method: 'POST',
          headers: {'Content-Type':'application/json'},
          body: JSON.stringify({cmd: value})
        });

        const data = await res.json().catch(()=>({error:'Bad JSON from server'}));

        if(!res.ok){
          appendLine(data.error || ('Error ' + res.status), 'line-err');
        } else {
          cwdPill.textContent = `cwd: ${data.cwd || '?'}`;
          codePill.textContent = `exit: ${data.code ?? '?'}`;

          if(data.stdout){
            data.stdout.split('\n').forEach(l=> { if(l.length) appendLine(l, 'line-ok'); });
          }
          if(data.stderr){
            data.stderr.split('\n').forEach(l=> { if(l.length) appendLine(l, 'line-err'); });
          }
          if(!data.stdout && !data.stderr){
            appendLine('(no output)', 'line-dim');
          }
        }
      } catch (e){
        appendLine(String(e), 'line-err');
      } finally {
        runBtn.disabled = false;
        cmd.focus();
      }
    }

    openTerminal.addEventListener('click', showTerm);
    closeTerminal.addEventListener('click', hideTerm);
    modalBack.addEventListener('click', (e)=>{ if(e.target === modalBack) hideTerm(); });

    runBtn.addEventListener('click', runCommand);
    clearBtn.addEventListener('click', ()=>{ termOut.innerHTML = ''; });

    cmd.addEventListener('keydown', (e)=>{
      if(e.key === 'Enter'){
        e.preventDefault();
        runCommand();
      }
      if(e.key === 'Escape'){
        hideTerm();
      }
    });

    document.addEventListener('keydown', (e)=>{
      // Ctrl+` opens terminal
      if(e.ctrlKey && (e.key === '`' || e.code === 'Backquote')){
        e.preventDefault();
        if(modalBack.style.display === 'flex') hideTerm();
        else showTerm();
      }
      if(e.key === 'Escape' && modalBack.style.display === 'flex'){
        hideTerm();
      }
    });

    // Initial hint
    appendLine('Terminal ready. Use Ctrl+` to toggle.', 'line-dim');

    // Prime cwd/exit pills
    (async ()=>{
      try{
        const res = await fetch('/api/ping');
        const data = await res.json();
        cwdPill.textContent = `cwd: ${data.cwd || '?'}`;
        codePill.textContent = `exit: ${data.code ?? 0}`;
      }catch{}
    })();
  </script>
</body>
</html>
HTML_EOF

# Title injection
safe_title="${WORDOC_TITLE//\\/\\\\}"
safe_title="${safe_title//\//\\/}"
safe_title="${safe_title//&/\\&}"
sed -i "s/__WORDOC_TITLE__/${safe_title}/g" "$HTML"

# ---------------- Python server (no pip deps) ----------------
cat > "$SERVER" <<'PY_EOF'
#!/usr/bin/env python3
import json
import os
import secrets
import subprocess
import sys
import threading
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler
from socketserver import ThreadingTCPServer

WORDOC_DIR = os.environ.get("WORDOC_DIR", os.path.expanduser("~/.cache/wordoc"))
HTML_PATH = os.path.join(WORDOC_DIR, "word-like.html")
STATE_PATH = os.environ.get("WORDOC_STATE", os.path.join(WORDOC_DIR, "state.json"))
TIMEOUT = int(os.environ.get("WORDOC_TIMEOUT", "300"))

# Persist one cwd for this single-user local app
cwd_lock = threading.Lock()
cwd = os.path.expanduser("~")

# Basic cookie gate (prevents random local pages from calling your API)
COOKIE_NAME = "wordoc_session"
SESSION = secrets.token_hex(16)

def read_body(rfile, length: int) -> bytes:
    data = b""
    while len(data) < length:
        chunk = rfile.read(length - len(data))
        if not chunk:
            break
        data += chunk
    return data

def parse_cookie(header: str):
    out = {}
    if not header:
        return out
    parts = header.split(";")
    for p in parts:
        if "=" in p:
            k, v = p.strip().split("=", 1)
            out[k] = v
    return out

class Handler(BaseHTTPRequestHandler):
    server_version = "wordoc/1.0"

    def log_message(self, fmt, *args):
        # quieter
        return

    def _send_json(self, code, payload):
        raw = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(raw)

    def _require_cookie(self):
        cookies = parse_cookie(self.headers.get("Cookie", ""))
        return cookies.get(COOKIE_NAME) == SESSION

    def _set_cookie(self):
        # HttpOnly prevents JS reading it; SameSite blocks most cross-site usage
        self.send_header("Set-Cookie", f"{COOKIE_NAME}={SESSION}; Path=/; HttpOnly; SameSite=Strict")

    def do_GET(self):
        if self.path == "/" or self.path.startswith("/?"):
            if not os.path.exists(HTML_PATH):
                self._send_json(HTTPStatus.INTERNAL_SERVER_ERROR, {"error":"HTML not found"})
                return
            with open(HTML_PATH, "rb") as f:
                data = f.read()

            self.send_response(HTTPStatus.OK)
            self._set_cookie()
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)
            return

        if self.path == "/api/ping":
            global cwd
            with cwd_lock:
                cur = cwd
            self._send_json(HTTPStatus.OK, {"ok":True, "cwd":cur, "code":0})
            return

        self._send_json(HTTPStatus.NOT_FOUND, {"error":"not found"})

    def do_POST(self):
        if self.path != "/api/run":
            self._send_json(HTTPStatus.NOT_FOUND, {"error":"not found"})
            return

        if not self._require_cookie():
            self._send_json(HTTPStatus.FORBIDDEN, {"error":"forbidden"})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            body = read_body(self.rfile, length)
            payload = json.loads(body.decode("utf-8") or "{}")
            cmd = (payload.get("cmd") or "").strip()
            if not cmd:
                self._send_json(HTTPStatus.BAD_REQUEST, {"error":"empty cmd"})
                return
        except Exception as e:
            self._send_json(HTTPStatus.BAD_REQUEST, {"error":f"bad request: {e}"})
            return

        global cwd
        # Handle "cd" persistently
        if cmd == "cd" or cmd.startswith("cd "):
            target = cmd[2:].strip() if cmd != "cd" else "~"
            target = os.path.expanduser(target) if target else os.path.expanduser("~")
            if not os.path.isabs(target):
                with cwd_lock:
                    target = os.path.normpath(os.path.join(cwd, target))
            try:
                if not os.path.isdir(target):
                    self._send_json(HTTPStatus.OK, {"stdout":"", "stderr":f"cd: no such directory: {target}", "code":1, "cwd":cwd})
                    return
                with cwd_lock:
                    cwd = target
                self._send_json(HTTPStatus.OK, {"stdout":"", "stderr":"", "code":0, "cwd":cwd})
                return
            except Exception as e:
                self._send_json(HTTPStatus.OK, {"stdout":"", "stderr":f"cd error: {e}", "code":1, "cwd":cwd})
                return

        # Run command via bash -lc so pipes/redirects work
        with cwd_lock:
            run_cwd = cwd

        try:
            p = subprocess.run(
                ["bash", "-lc", cmd],
                cwd=run_cwd,
                capture_output=True,
                text=True,
                timeout=TIMEOUT
            )
            self._send_json(HTTPStatus.OK, {
                "stdout": p.stdout or "",
                "stderr": p.stderr or "",
                "code": int(p.returncode),
                "cwd": run_cwd
            })
        except subprocess.TimeoutExpired:
            self._send_json(HTTPStatus.OK, {
                "stdout": "",
                "stderr": f"Command timed out after {TIMEOUT}s",
                "code": 124,
                "cwd": run_cwd
            })
        except Exception as e:
            self._send_json(HTTPStatus.OK, {
                "stdout": "",
                "stderr": f"Run error: {e}",
                "code": 1,
                "cwd": run_cwd
            })

def main():
    os.makedirs(WORDOC_DIR, exist_ok=True)

    # Bind local only, random port
    with ThreadingTCPServer(("127.0.0.1", 0), Handler) as httpd:
        port = httpd.server_address[1]
        # write state so bash can open correct URL
        with open(STATE_PATH, "w", encoding="utf-8") as f:
            json.dump({"port": port}, f)

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass

if __name__ == "__main__":
    main()
PY_EOF

chmod +x "$SERVER"
rm -f "$STATE"

# Start server
export WORDOC_DIR
export WORDOC_STATE="$STATE"
export WORDOC_TIMEOUT="$WORDOC_TIMEOUT"

python3 "$SERVER" &
SVPID="$!"

# Wait for state.json (port)
for _ in $(seq 1 200); do
  if [[ -s "$STATE" ]]; then break; fi
  sleep 0.05
done
[[ -s "$STATE" ]] || { echo "ERROR: server did not start."; kill "$SVPID" 2>/dev/null || true; exit 1; }

PORT="$(python3 - <<PY
import json
print(json.load(open("$STATE"))["port"])
PY
)"

URL="http://127.0.0.1:${PORT}/"

# ---- Find a browser we can run ----
BROWSER=""
for c in chromium chromium-browser google-chrome brave firefox xdg-open; do
  if command -v "$c" >/dev/null 2>&1; then
    BROWSER="$c"
    break
  fi
done

if [[ -z "$BROWSER" ]]; then
  echo "Server running at: $URL"
  echo "Open it manually in a browser."
  wait "$SVPID"
  exit 0
fi

# Launch
case "$BROWSER" in
  chromium|chromium-browser|google-chrome|brave)
    mkdir -p "$PROFILE"
    if [[ "$MODE" == "kiosk" ]]; then
      "$BROWSER" \
        --user-data-dir="$PROFILE" \
        --kiosk \
        --app="$URL" \
        --force-device-scale-factor="$WORDOC_SCALE" \
        --no-first-run \
        --no-default-browser-check \
        --disable-features=TranslateUI \
        --disable-session-crashed-bubble \
        --disable-infobars \
        --hide-scrollbars \
        --overscroll-history-navigation=0 >/dev/null 2>&1 &
    else
      "$BROWSER" \
        --user-data-dir="$PROFILE" \
        --app="$URL" \
        --window-size=1400,900 \
        --force-device-scale-factor="$WORDOC_SCALE" \
        --no-first-run \
        --no-default-browser-check \
        --disable-features=TranslateUI \
        --disable-session-crashed-bubble \
        --disable-infobars \
        --hide-scrollbars >/dev/null 2>&1 &
    fi
    ;;
  firefox)
    if [[ "$MODE" == "kiosk" ]]; then firefox --kiosk "$URL" >/dev/null 2>&1 & else firefox "$URL" >/dev/null 2>&1 & fi
    ;;
  xdg-open)
    xdg-open "$URL" >/dev/null 2>&1 &
    ;;
  *)
    "$BROWSER" "$URL" >/dev/null 2>&1 &
    ;;
esac

echo "Word-style UI running at: $URL"
echo "Open Terminal: click 'Terminal' (bottom right) or press Ctrl+\`"
echo "Stop server: Ctrl+C here"

trap 'kill "$SVPID" 2>/dev/null || true' EXIT
wait "$SVPID"
