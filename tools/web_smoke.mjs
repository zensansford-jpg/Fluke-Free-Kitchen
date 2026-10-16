#!/usr/bin/env node
/**
 * Drives the exported web build in a real browser and reports what happened.
 *
 * `--headless --screenshot` only captures a moment, and a Godot web build spends
 * the first several seconds compiling a ~39 MB WebAssembly module and loading the
 * `.pck`. This connects to a running Chrome over the DevTools protocol, waits as
 * long as the game actually needs, collects every console message and page error,
 * reads the state of the canvas, and then captures a screenshot.
 *
 * It needs a Chrome started with remote debugging, for example:
 *
 *   chrome --headless=new --remote-debugging-port=9222 \
 *          --remote-allow-origins=* --enable-unsafe-swiftshader --no-sandbox \
 *          --user-data-dir=<temp> about:blank
 *
 * Then:
 *
 *   node tools/web_smoke.mjs --url http://localhost:8060/ --out web.png --wait 30000
 *
 * Exit code is 0 only when the page produced no console errors/exceptions and a
 * canvas of a sensible size exists.
 */

import { writeFileSync } from "node:fs";

function parseArgs(argv) {
  const args = { url: "http://localhost:8060/", out: "web_shot.png", wait: 30000, port: 9222 };
  for (let i = 2; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (key === "--url") args.url = value;
    else if (key === "--out") args.out = value;
    else if (key === "--wait") args.wait = Number(value);
    else if (key === "--port") args.port = Number(value);
  }
  return args;
}

/** Minimal CDP client over a WebSocket. */
class Session {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    this.events = [];
    ws.addEventListener("message", (event) => {
      const message = JSON.parse(event.data);
      if (message.id && this.pending.has(message.id)) {
        const { resolve, reject } = this.pending.get(message.id);
        this.pending.delete(message.id);
        if (message.error) reject(new Error(JSON.stringify(message.error)));
        else resolve(message.result);
      } else if (message.method) {
        this.events.push(message);
      }
    });
  }

  send(method, params = {}) {
    this.id += 1;
    const id = this.id;
    this.ws.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`timed out: ${method}`));
        }
      }, 60000);
    });
  }
}

async function main() {
  const args = parseArgs(process.argv);
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  const list = await (await fetch(`http://127.0.0.1:${args.port}/json/list`)).json();
  const page = list.find((entry) => entry.type === "page");
  if (!page) throw new Error("no page target; is Chrome running with --remote-debugging-port?");

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    ws.addEventListener("open", resolve, { once: true });
    ws.addEventListener("error", reject, { once: true });
  });

  const session = new Session(ws);
  await session.send("Page.enable");
  await session.send("Runtime.enable");
  await session.send("Log.enable");

  console.log(`--- Fluke Free Kitchen web build check ---`);
  console.log(`  opening ${args.url}`);
  await session.send("Page.navigate", { url: args.url });
  await sleep(args.wait);

  // What does the page look like now?
  const probe = await session.send("Runtime.evaluate", {
    expression: `(() => {
      const c = document.querySelector('canvas');
      return JSON.stringify({
        title: document.title,
        canvas: c ? { w: c.width, h: c.height, cw: c.clientWidth, ch: c.clientHeight } : null,
        engine: (typeof Engine !== 'undefined') ? 'Engine global present' : 'no Engine global',
      });
    })()`,
    returnByValue: true,
  });
  const state = JSON.parse(probe.result.value);

  const problems = [];
  for (const event of session.events) {
    if (event.method === "Runtime.exceptionThrown") {
      const d = event.params.exceptionDetails;
      problems.push(`exception: ${d.exception?.description ?? d.text}`);
    } else if (event.method === "Runtime.consoleAPICalled" && event.params.type === "error") {
      problems.push(`console.error: ${event.params.args.map((a) => a.value ?? a.description).join(" ")}`);
    } else if (event.method === "Log.entryAdded" && event.params.entry.level === "error") {
      problems.push(`log: ${event.params.entry.text}`);
    }
  }

  const shot = await session.send("Page.captureScreenshot", { format: "png" });
  writeFileSync(args.out, Buffer.from(shot.data, "base64"));

  console.log(`  title: ${state.title}`);
  console.log(`  canvas: ${JSON.stringify(state.canvas)}`);
  console.log(`  ${state.engine}`);
  console.log(`  screenshot: ${args.out}`);
  for (const problem of problems) console.log(`  ERROR ${problem}`);

  const canvasOk = state.canvas && state.canvas.w > 100 && state.canvas.h > 100;
  if (!canvasOk) problems.push("no usable canvas: the build did not start rendering");
  ws.close();

  console.log(`--- results ---`);
  if (problems.length === 0) {
    console.log("WEB BUILD CHECK PASSED (page loaded, canvas present, no console errors)");
    process.exit(0);
  }
  console.log(`WEB BUILD CHECK FAILED (${problems.length} problems)`);
  process.exit(1);
}

main().catch((error) => {
  console.error(`WEB BUILD CHECK FAILED: ${error.message}`);
  process.exit(1);
});
