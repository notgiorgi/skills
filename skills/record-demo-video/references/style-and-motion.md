# Style and motion

## Visual reference

Inspect the [Lightdash social studio](https://lightdash-social-studio.vercel.app/) and choose templates suited to the story: product posts for screenshot framing, before/after for comparison, big-number cards for a measurable result, event layouts for a punchy reveal. Treat these as visual references; write the demo's own copy and use sanitized product data.

The kit combines black or white space, purple accents, large concise headlines and geometric block motifs. Its product layouts keep the screenshot prominent. Britti Sans is the main display face; Space Grotesk appears in punchier event headlines, with Inter for supporting UI. Use available, licensed fonts or a close local sans-serif fallback.

For a purple direction, set `canvas.accent` to `5e4cff`; `d1ccff` is a useful pale counterpart. Inspect the selected template for its background and text contrast. The bundled card is a starting point: adapt `assets/card.html` in a demo-local copy when the composition needs more than its color controls. Keep the source kit URL in the demo notes so a re-cut can revisit it.

## Motion

Record the app at a stable viewport with `agent-browser`; create editorial camera moves and transitions in the render. Browser page zoom changes layout, so use it for intentional setup before a take. Check the installed CLI's `record --help` when capture options matter.

- **Zoom** toward a small control or result after establishing the full view. Start around 1.15–1.5× over 0.5–0.9 seconds, hold while it is read, then return to context when needed. Split the take into adjacent plan items to zoom in, hold and zoom out at different moments. Capture enough resolution for the closest crop.
- **Transition** when the story changes time, context or viewpoint. A 0.25–0.45 second dissolve, slide or wipe can connect beats. Use direct cuts for continuous actions; preserve the cause and result across the edit.
- **Continuity** comes from real interactions, cursor movement and app animation. Let those play. Place occasional editorial motion where it directs attention; choose a small, consistent motion vocabulary for the video.

The renderer supports eased zooms on clips and stills, incoming transitions on any item, and hard cuts elsewhere. It overlaps items during transitions: leave readable handles around proving moments and account for the shorter running time. A static title can transition into a live take; title cards are optional.
