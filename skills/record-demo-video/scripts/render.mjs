#!/usr/bin/env node
// Cut agent-browser takes into a finished video from a JSON plan.
//
//   node render.mjs <plan.json>                     render every item (cached) and join them
//   node render.mjs frame <plan.json> <take> <at> <out.jpg>   the frame of a take at a time or log label
//   node render.mjs sheet <video> <out.jpg> [seconds]         contact sheet, one tile per [seconds] (default 3)
//
// Plan format: references/plan.md. Needs ffmpeg and agent-browser (for the cards) on PATH.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const CARD = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "assets", "card.html");
const [cmd, ...args] = process.argv.slice(2);
const run = (bin, a) => execFileSync(bin, a, { stdio: ["ignore", "pipe", "inherit"] }).toString();
const ffmpeg = (a) => run("ffmpeg", ["-y", "-hide_banner", "-loglevel", "error", ...a]);
const probe = (file, entries) => run("ffprobe", ["-v", "error", "-show_entries", entries, "-of", "csv=p=0", file]).trim();

if (cmd === "sheet") {
  const [video, out, every = "3"] = args;
  ffmpeg(["-i", video, "-vf", `fps=1/${every},scale=480:-2,tile=5x6`, "-frames:v", "1", out]);
  console.log(`${out}: the first 30 tiles, one per ${every}s; add -ss to ffmpeg for later stretches`);
  process.exit(0);
}

const planPath = path.resolve(cmd === "frame" ? args[0] : cmd ?? "");
if (!cmd || !fs.existsSync(planPath)) {
  console.error("usage: see the header of render.mjs");
  process.exit(2);
}
const base = path.dirname(planPath);
const plan = JSON.parse(fs.readFileSync(planPath, "utf8"));
const at = (p) => path.resolve(base, p);
const takesDir = at(plan.takes ?? "takes");
const takeFile = (take) => path.join(takesDir, `${take}.mp4`);

// A time in a take: seconds, or a label from takes/<take>.log with an optional offset ("sent", "done+1.5s", "end-500ms").
function time(take, ref) {
  if (typeof ref === "number") return ref;
  if (ref === undefined || ref === "start") return 0;
  const m = /^(.*?)(?:([+-])(\d+(?:\.\d+)?)(ms|s))?$/.exec(String(ref).trim());
  const log = path.join(takesDir, `${take}.log`);
  const labels = fs.existsSync(log)
    ? Object.fromEntries(fs.readFileSync(log, "utf8").trim().split("\n").filter(Boolean).map((l) => { const [t, ...n] = l.split(" "); return [n.join(" "), Number(t)]; }))
    : {};
  if (m[1] === "end" && !("end" in labels)) labels.end = Number(probe(takeFile(take), "format=duration"));
  if (!(m[1] in labels)) throw new Error(`take ${take} has no mark "${m[1]}" (has: ${Object.keys(labels).join(", ")})`);
  const off = m[3] ? Number(m[3]) * (m[4] === "s" ? 1 : 0.001) * (m[2] === "-" ? -1 : 1) : 0;
  return Math.max(0, labels[m[1]] + off);
}

if (cmd === "frame") {
  const [, take, ref, out] = args;
  ffmpeg(["-ss", String(time(take, ref)), "-i", takeFile(take), "-frames:v", "1", out]);
  console.log(`${out}: ${take} at ${time(take, ref).toFixed(2)}s`);
  process.exit(0);
}

const canvas = { width: 1920, height: 1080, band: 54, bg: "0e0f11", fg: "f3f4f6", muted: "8b93a1", accent: "8ab4ff", eyebrow: "", ...plan.canvas };
const W = canvas.width, H = canvas.height, BAND = canvas.band, BG = `0x${canvas.bg}`;
const work = at(plan.work ?? "render");
fs.mkdirSync(work, { recursive: true });
const hash = (o) => crypto.createHash("sha1").update(JSON.stringify(o)).digest("hex").slice(0, 12);
const even = (n) => Math.round(n / 2) * 2;

// Where a take sits under the caption band, so captions line up with its left edge.
function boxFor(take) {
  const [w, h] = probe(takeFile(take), "stream=width,height").split(",").map(Number);
  const s = Math.min(W / w, (H - BAND) / h);
  return { w: even(w * s), h: even(h * s), x: even((W - even(w * s)) / 2) };
}

const pending = [];
function card(params, kind) {
  const q = new URLSearchParams({ kind, bg: canvas.bg, fg: canvas.fg, muted: canvas.muted, accent: canvas.accent });
  for (const [k, v] of Object.entries(params)) if (v !== undefined && v !== "") q.set(k, String(v));
  const file = path.join(work, `${kind}-${hash(q.toString())}.png`);
  if (!fs.existsSync(file)) pending.push({ file, url: `file://${CARD}?${q}`, h: kind === "title" ? H : BAND });
  return file;
}
function shootCards() {
  if (!pending.length) return;
  const ab = (...a) => run("agent-browser", ["--session", "record-demo-video-cards", ...a]);
  for (const c of pending) {
    ab("set", "viewport", String(W), String(c.h));
    ab("open", c.url);
    ab("screenshot", c.file);
  }
  ab("close");
}

const enc = ["-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p", "-r", "30", "-an"];
const fit = `scale=${W}:${H - BAND}:force_original_aspect_ratio=decrease:flags=lanczos,pad=${W}:${H}:(ow-iw)/2:${BAND}+(${H - BAND}-ih)/2:color=${BG},setsar=1`;
const withCaption = (chain, capPng, inputs) => {
  if (!capPng) return `[0:v]${chain},format=yuv420p[v]`;
  inputs.push("-i", capPng);
  return `[0:v]${chain}[b];[b][1:v]overlay=0:0,format=yuv420p[v]`;
};

const firstClip = plan.items.find((i) => i.clip);
const captionLeft = firstClip ? boxFor(firstClip.clip).x : 40;
const segments = plan.items.map((item, i) => {
  const kind = item.clip ? "clip" : item.still ? "still" : "title";
  let cap, key = { item, canvas };
  if (kind === "clip") {
    const box = boxFor(item.clip);
    key = { ...key, span: [time(item.clip, item.from), time(item.clip, item.to)], size: fs.statSync(takeFile(item.clip)).size };
    if (item.caption) cap = card({ ...item.caption, left: box.x }, "caption");
  } else if (kind === "still" && item.caption) cap = card({ ...item.caption, left: captionLeft }, "caption");
  const png = kind === "title" ? card({ eyebrow: item.eyebrow ?? canvas.eyebrow, step: item.step, title: item.title, sub: item.sub }, "title") : null;
  return { i, kind, item, cap, png, out: path.join(work, `${kind}-${hash(key)}.mp4`) };
});
shootCards();

for (const s of segments) {
  const done = s.out;
  s.out = done.replace(/\.mp4$/, ".part.mp4");
  const name = `${String(s.i + 1).padStart(2)} ${s.kind.padEnd(5)}`;
  if (fs.existsSync(done)) { s.out = done; console.log(`${name} cached`); continue; }
  const it = s.item, inputs = [];
  if (s.kind === "title") {
    const secs = it.seconds ?? 2.4;
    ffmpeg(["-loop", "1", "-t", String(secs), "-i", s.png, "-vf", `fps=30,format=yuv420p,fade=t=in:d=0.35:color=${BG},fade=t=out:st=${Math.max(0, secs - 0.35)}:d=0.35:color=${BG}`, ...enc, s.out]);
    console.log(`${name} ${secs}s  ${it.title}`);
  } else if (s.kind === "still") {
    const secs = it.seconds ?? 4;
    inputs.push("-loop", "1", "-t", String(secs), "-i", at(it.still));
    const f = withCaption(`${fit},fps=30,fade=t=in:d=0.3:color=${BG}`, s.cap, inputs);
    ffmpeg([...inputs, "-filter_complex", f, "-map", "[v]", ...enc, s.out]);
    console.log(`${name} ${secs}s  ${it.still}`);
  } else {
    const from = time(it.clip, it.from), to = time(it.clip, it.to), speed = it.speed ?? 1;
    inputs.push("-ss", from.toFixed(3), "-to", to.toFixed(3), "-i", takeFile(it.clip));
    // squeeze drops repeated frames (stillness) before the speed-up; hold freezes the last frame
    const chain = `${it.squeeze ? "mpdecimate,setpts=N/30/TB," : ""}setpts=PTS/${speed},fps=30,${fit}${it.hold ? `,tpad=stop_mode=clone:stop_duration=${it.hold}` : ""}`;
    const f = withCaption(chain, s.cap, inputs);
    ffmpeg([...inputs, "-filter_complex", f, "-map", "[v]", ...enc, s.out]);
    console.log(`${name} ${Number(probe(s.out, "format=duration")).toFixed(1)}s  ${it.clip} ${it.from ?? "start"} → ${it.to ?? "end"} at ${speed}x`);
  }
  fs.renameSync(s.out, done);
  s.out = done;
}

const list = path.join(work, "segments.txt");
fs.writeFileSync(list, segments.map((s) => `file '${s.out}'`).join("\n") + "\n");
const out = at(plan.out ?? "demo.mp4");
ffmpeg(["-f", "concat", "-safe", "0", "-i", list, "-c", "copy", "-movflags", "+faststart", out]);
const expected = segments.reduce((sum, s) => sum + Number(probe(s.out, "format=duration")), 0);
const got = Number(probe(out, "format=duration"));
if (Math.abs(got - expected) > 0.5) throw new Error(`joined video is ${got.toFixed(1)}s, expected ${expected.toFixed(1)}s; delete ${work} and render again`);
console.log(`${out}: ${Number(probe(out, "format=duration")).toFixed(1)}s, ${W}x${H}, 30 fps`);
