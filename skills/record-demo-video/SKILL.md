---
name: record-demo-video
description: Record and edit a feature demo with a tailored story, visual style and motion.
disable-model-invocation: true
---

# Demo video

A demo video is a pipeline: **script** the scenes, **record** one take per step with `agent-browser`, **edit** from a plan, **review**, **deliver**. The takes, their time logs and the plan are kept, so a re-cut (captions, speed, order, trims) is a plan change and one render.

Default output is **1920×1080 at 30 fps**, H.264. Choose the length and presentation for the feature and audience: a small interaction may need 30 seconds; a workflow may need several minutes. Titles, captions, chapters, intro and outro are optional editorial tools. Keep recorded interactions and editorial motion smooth.

Work in one directory, `DEMO_DIR`: `takes/` (videos and time logs), `plan.json`, `render/` (cache) and the output. The skill's `scripts/drive.sh` drives the app smoothly and logs takes; `scripts/render.mjs` cuts the video. They need `agent-browser`, `ffmpeg`, `perl` and `node`.

## 1. Script

Choose what the viewer should understand and a structure that proves it. A continuous walkthrough, result-first reveal, before/after comparison, focused interaction or several connected scenes can all work. Let the feature determine the beats, their order and pacing.

Use the [Lightdash social studio](https://lightdash-social-studio.vercel.app/) as the visual reference for cards, typography, palette and framing. Inspect relevant templates before designing; read [references/style-and-motion.md](references/style-and-motion.md) when choosing styling, zooms or transitions.

Write the beats: actions, framing, approximate duration and the **proving moment**, the visible evidence that the feature worked (the item rendered, a status reading Published, the merged result). Plan where a close-up or transition helps the viewer follow the action.

Done when the story has a clear outcome, every claim has a proving moment, and the planned length and visual direction fit the feature.

## 2. Connect

```bash
cd "$DEMO_DIR"; CDP_PORT=<port> source <skill>/scripts/drive.sh
ab tab list            # pick the app's main page with `ab tab <id>`
ab screenshot start.png
```

`CDP_PORT` is the app's remote debugging port (an Electron app, or Chrome started with `--remote-debugging-port`).

Check the window's size: a take records at the window's device pixels (a 1280×840 window at 2× density records 2560×1680). Capture enough pixels for the planned framing and close-ups; the default caption band leaves 1026 px of picture height at 1080p.

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

- Pace typing and waits around comprehension. Trim a wait or speed it up; label acceleration when elapsed time matters to the claim.
- After a sped-up wait, return to 1× and let the proving moment be read; 2 to 4 seconds is a useful starting point.
- Trim dead time between actions with the cut points rather than speeding it up.
- Add cards and captions where they supply missing context. Consecutive clips can carry the story directly.
- Use the plan's `zoom` for an eased close-up and `transition` for a short dissolve, slide or wipe between beats. These are render-time effects; `agent-browser` supplies the original recording. See [style and motion](references/style-and-motion.md) for choosing them and [plan format](references/plan.md) for supported fields.

`render.mjs frame plan.json <take> <time or label> out.jpg` shows a take at a moment, to place a cut.

## 5. Review

Make contact sheets with `render.mjs sheet demo.mp4 sheet.jpg [seconds]` and look at every tile, including later stretches beyond the first 30 tiles. Check that proving moments stay readable, captions match the picture, pacing fits the chosen length, and no private data, stray dialog or unexplained error is visible. Play each zoom and transition: the target stays in frame, text remains sharp, and the viewer can follow the change.

Check motion is smooth where it matters: `ffmpeg -ss <from> -to <to> -i takes/<take>.mp4 -vf mpdecimate -f null -` reports `frame=` near 30 a second for smooth motion, and a handful for jumps.

Done when every scene passes. Otherwise change the plan, or redo a take, and render again.

## 6. Deliver

Report the video's path, length and resolution, and every cut that hides something (a failure, a retry, a fix made mid-take). Keep `DEMO_DIR` and say where it is; offer to move it out of `/tmp`, which a reboot can clear.
