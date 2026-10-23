# plan.json

Paths are relative to the plan file. Items play in order.

```json
{
  "takes": "takes",
  "out": "demo.mp4",
  "canvas": { "eyebrow": "Example app" },
  "items": [
    { "title": "Example app, end to end", "sub": "Build a report, then undo a change.", "seconds": 3.4 },
    { "clip": "01-ask", "from": "start", "to": "sent", "speed": 1.5,
      "caption": { "step": "1", "title": "Build a report", "sub": "Ask for it" } },
    { "clip": "01-ask", "from": "sent", "to": "done", "speed": 20,
      "caption": { "step": "1", "title": "Build a report", "sub": "The report builds  ·  20× speed" } },
    { "clip": "01-ask", "from": "done", "to": "done+3s",
      "zoom": { "from": 1, "to": 1.3, "x": 0.65, "y": 0.45, "seconds": 0.7 },
      "caption": { "step": "1", "title": "Build a report", "sub": "The finished report" } },
    { "still": "elsewhere.png", "seconds": 4,
      "transition": { "type": "slideleft", "seconds": 0.35 },
      "caption": { "step": "2", "title": "Meanwhile", "sub": "A teammate edits the same report elsewhere" } }
  ]
}
```

## Items

- **Title card**: `title`, optional `step` (a pill above it), `sub`, `eyebrow` (overrides the canvas one), `seconds` (default 2.4). Fades in.
- **Clip**: `clip` names a take (`takes/<clip>.mp4`). `from` and `to` are seconds or marks from `takes/<clip>.log`, with an optional offset: `"sent"`, `"done+3s"`, `"tile-500ms"`; `start` and `end` always exist. `speed` (default 1). `hold` freezes the last frame for that many seconds. `squeeze: true` drops repeated frames before the speed-up, for a wait full of stillness; it erases still moments, so keep it off a clip that ends on a proving moment.
- **Still**: `still` (an image path), `seconds` (default 4). For something captured outside the app, such as a screenshot of another tool.

Clips and stills take an optional `caption`: `title`, optional `step` and `sub`. It renders as a band above the picture, aligned with the take's left edge.

Choose any sequence of items; a video can consist entirely of live clips. Cards, numbered steps and captions are optional.

## Zooms and transitions

Clips and stills accept `zoom`. Scales `from` and `to` default to 1 and 1.3 (range 1–4). `x` and `y` are the normalized focal point in the fitted picture, excluding the caption band: 0 is left/top, 1 is right/bottom, default 0.5. The crop stays within the picture's edges. `start` is output seconds into the item (default 0); `seconds` is the move's duration (default 0.7). The zoom eases in and out, then holds its final framing. Set equal scales for a fixed close-up, or `from: 1.3, to: 1` to pull back. `hold` freezes the final rendered frame, including its zoom.

Any item after the first accepts an incoming `transition`: `type` is `fade` (default), `slideleft` or `wipeleft`; `seconds` defaults to 0.35 and is rounded to a 30 fps frame. Its duration must be positive and shorter than half of either neighboring item. Transitions overlap the end of the previous item and the start of this item, shortening total duration by the overlap. Leave handles so important actions and proving moments remain readable. Omit `transition` for a hard cut.

See [style and motion](style-and-motion.md) for the visual kit and editorial choices.

## Canvas

Every key is optional.

| Key | Default |
|---|---|
| `width`, `height` | 1920, 1080 |
| `band` (caption band height) | 54 |
| `bg`, `fg`, `muted`, `accent` (hex without `#`) | `0e0f11`, `f3f4f6`, `8b93a1`, `8ab4ff` |
| `eyebrow` (the small line above every title) | none |

Takes are scaled to fit under the band and centred. Set `band: 0` for a full-height picture with no captions. Cards are drawn from `assets/card.html` with `agent-browser`.

## Cache

`render/` keeps one video per item, named by a hash of the item, the canvas and the take's cut times. Changing one item re-renders only that item; a re-recorded take re-renders its clips. Delete `render/` to force a full render.
