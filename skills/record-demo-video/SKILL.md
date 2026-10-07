---
name: record-demo-video
description: Record and edit a demo video of a running app, with scripted scenes, title cards, captions and sped-up waits.
disable-model-invocation: true
---

# Demo video

A demo video is a pipeline: **script** the scenes, **record** one take per step with `agent-browser`, **edit** from a plan, **review**, **deliver**. The takes, their time logs and the plan are kept, so a re-cut (captions, speed, order, trims) is a plan change and one render.

The deliverable is **1920×1080 at 30 fps**, H.264, about 2 to 4 minutes. Each scene opens on a title card, every clip carries a caption band naming the scene and what is happening, and every motion on screen is **smooth**: it changes the picture on nearly every frame, as a person's hand would.

Work in one directory, `DEMO_DIR`: `takes/` (videos and time logs), `plan.json`, `render/` (cache) and the output. The skill's `scripts/drive.sh` drives the app smoothly and logs takes; `scripts/render.mjs` cuts the video. They need `agent-browser`, `ffmpeg`, `perl` and `node`.

## 1. Script

Write the scene list: for each scene a title, the actions, and the **proving moment**, the thing on screen that shows the scene worked (the item rendered, a status reading Published, the merged result).

Done when every scene names its proving moment.

## 2. Connect

```bash
cd "$DEMO_DIR"; CDP_PORT=<port> source <skill>/scripts/drive.sh
ab tab list            # pick the app's main page with `ab tab <id>`
ab screenshot start.png
```

`CDP_PORT` is the app's remote debugging port (an Electron app, or Chrome started with `--remote-debugging-port`).

Check the window's size: a take records at the window's device pixels (a 1280×840 window at 2× density records 2560×1680). Its height must be at least 1026 px to fill 1080p under the caption band; resize the window first when it is smaller.

Use a scratch profile or account, so nothing private reaches the video. Make one real request against every backend the scenes depend on and confirm it answers quickly: a slow or broken backend ruins a take that costs minutes to redo.

Done when the screenshot shows the starting state, the size fits, and the backends answer.

## 3. Record

Record one take per step of a scene: `take 01-ask` starts `takes/01-ask.mp4` (saving the previous take), `ab record stop` ends the last. Log every moment the edit will cut on with `mark <label>`; it writes seconds since the take started, and works across shell calls.

Drive with the helpers, which keep motion smooth:

- `ref '<pattern>'` returns an element ref from a fresh snapshot (`ref 'textbox "Reply'`). Refs go stale when the page changes; look them up again.
- `go @e12` glides the cursor to an element and clicks. `glide @e12` only hovers, which reveals hover-only controls.
- `typeit "<text>"` types into the focused element at about 20 characters a second.
- `glance "<css selector>"` scrolls an element to the middle of the view; `ab eval "window.scrollBy({top: 800, behavior: 'smooth'})"` scrolls a page.
- Wait on the app, never a fixed sleep: `ab wait --text "Published" --timeout 900000`, or `ab wait --fn "<js>" --timeout …`. The default timeout is 25 seconds.
- Select-all on macOS is `Meta+a`.

`agent-browser`'s own `click`, `scroll` and `keyboard type` work but jump on video: a glide of a few steps, a scroll in steps, a whole sentence in one frame. Keep them to setup that is cut out.

Embedded web content (an Electron `<webview>`, a cross-origin frame) records fine but is its own tab: the cursor draws underneath it, and clicks, hovers and wheel events miss it. Drive it from a second session on its tab, `DEMO_SESSION=demo-inner ab tab <its id>`, then scroll it there with `DEMO_SESSION=demo-inner ab eval "window.scrollBy({top: 800, behavior: 'smooth'})"`.

After each scene, take a screenshot and look at it before starting the next. A broken step is cheapest to redo now, as a new take that starts where the good one ended; the cut joins on the same frame. When something outside the app breaks, fix it, then redo the step or plan a cut around it, and note what the cut hides for the delivery note.

Done when every scene's takes show its proving moment and every cut point is marked.

## 4. Edit

Write `plan.json` (format in [references/plan.md](references/plan.md)), then run `node <skill>/scripts/render.mjs plan.json`. It renders each item once, caches it, and joins them; rerun after every plan change.

- Typing plays at about 1.5×. A wait plays fast enough to last 10 to 20 seconds, so 4× to 40×, with the speed in its caption.
- After a sped-up wait, cut back to 1× for 2 to 4 seconds on the proving moment, so it can be read.
- Trim dead time between actions with the cut points rather than speeding it up.
- One title card per scene, about 2.4 seconds, and a short intro and outro.

`render.mjs frame plan.json <take> <time or label> out.jpg` shows a take at a moment, to place a cut.

## 5. Review

Make contact sheets with `render.mjs sheet demo.mp4 sheet.jpg [seconds]` and look at every tile. Check each scene's proving moment stays on screen long enough to read, captions match what is shown, the total is within 2 to 4 minutes, and no private data, stray dialog or unexplained error is visible.

Check motion is smooth where it matters: `ffmpeg -ss <from> -to <to> -i takes/<take>.mp4 -vf mpdecimate -f null -` reports `frame=` near 30 a second for smooth motion, and a handful for jumps.

Done when every scene passes. Otherwise change the plan, or redo a take, and render again.

## 6. Deliver

Report the video's path, length and resolution, and every cut that hides something (a failure, a retry, a fix made mid-take). Keep `DEMO_DIR` and say where it is; offer to move it out of `/tmp`, which a reboot can clear.
