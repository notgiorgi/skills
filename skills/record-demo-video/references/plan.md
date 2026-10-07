# plan.json

Paths are relative to the plan file. Items play in order.

```json
{
  "takes": "takes",
  "out": "demo.mp4",
  "canvas": { "eyebrow": "Example app" },
  "items": [
    { "title": "Example app, end to end", "sub": "Build a report, then undo a change.", "seconds": 3.4 },
    { "title": "Build a report", "step": "1 of 2", "sub": "Describe it and watch it appear." },
    { "clip": "01-ask", "from": "start", "to": "sent", "speed": 1.5,
      "caption": { "step": "1", "title": "Build a report", "sub": "Ask for it" } },
    { "clip": "01-ask", "from": "sent", "to": "done", "speed": 20,
      "caption": { "step": "1", "title": "Build a report", "sub": "The report builds  ·  20× speed" } },
    { "clip": "01-ask", "from": "done", "to": "done+3s",
      "caption": { "step": "1", "title": "Build a report", "sub": "The finished report" } },
    { "still": "elsewhere.png", "seconds": 4,
      "caption": { "step": "2", "title": "Meanwhile", "sub": "A teammate edits the same report elsewhere" } }
  ]
}
```

## Items

- **Title card**: `title`, optional `step` (a pill above it), `sub`, `eyebrow` (overrides the canvas one), `seconds` (default 2.4). Fades in and out.
- **Clip**: `clip` names a take (`takes/<clip>.mp4`). `from` and `to` are seconds or marks from `takes/<clip>.log`, with an optional offset: `"sent"`, `"done+3s"`, `"tile-500ms"`; `start` and `end` always exist. `speed` (default 1). `hold` freezes the last frame for that many seconds. `squeeze: true` drops repeated frames before the speed-up, for a wait full of stillness; it erases still moments, so keep it off a clip that ends on a proving moment.
- **Still**: `still` (an image path), `seconds` (default 4). For something captured outside the app, such as a screenshot of another tool.

Clips and stills take an optional `caption`: `title`, optional `step` and `sub`. It renders as a band above the picture, aligned with the take's left edge.

## Canvas

Every key is optional.

| Key | Default |
|---|---|
| `width`, `height` | 1920, 1080 |
| `band` (caption band height) | 54 |
| `bg`, `fg`, `muted`, `accent` (hex without `#`) | `0e0f11`, `f3f4f6`, `8b93a1`, `8ab4ff` |
| `eyebrow` (the small line above every title) | none |

Takes are scaled to fit under the band and centred. Cards are drawn from `assets/card.html` with `agent-browser`.

## Cache

`render/` keeps one video per item, named by a hash of the item, the canvas and the take's cut times. Changing one item re-renders only that item; a re-recorded take re-renders its clips. Delete `render/` to force a full render.
