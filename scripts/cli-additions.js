/**
 * cli-additions.js
 * ─────────────────────────────────────────────────────────────────────────────
 * New CLI commands used by the GitHub Actions workflow SSH dispatch.
 * Add these cases to the switch statement in your existing cli.js.
 *
 * Commands:
 *   add-raw      <title> <body> <priority> <agentId> <source> <ref> <workdir>
 *   pipeline-raw <title> <body> <agents_csv> <ref> <source> <workdir>
 *   task-json    <id>
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * INTEGRATION: Copy the switch cases below into your cli.js file.
 * Or run this file standalone: node cli-additions.js <command> [args...]
 */

// ── Paste these cases into cli.js ────────────────────────────────────────────
/*

case "add-raw": {
  // title body priority agentId source ref workdir
  const [,, title, body, priority, agentId, source, ref, workdir] = args;
  if (!title || !body) {
    process.stderr.write("Usage: add-raw <title> <body> <priority> <agentId> <source> <ref> <workdir>\n");
    process.exit(1);
  }
  const result = await api("/tasks", "POST", {
    title,
    body,
    agentId:   agentId && agentId !== "" ? agentId : null,
    priority:  parseInt(priority || "5"),
    source:    source || "github",
    sourceRef: ref || null,
    workdir:   workdir || null,
  });
  // Print ONLY the task ID — captured by SSH in the workflow
  process.stdout.write(result.id + "\n");
  break;
}

case "pipeline-raw": {
  // title body agents_csv ref source workdir
  const [,, title, body, agentsCsv, ref, source, workdir] = args;
  if (!title || !body || !agentsCsv) {
    process.stderr.write("Usage: pipeline-raw <title> <body> <agents_csv> <ref> <source> <workdir>\n");
    process.exit(1);
  }
  const agents = agentsCsv.split(",").map(s => s.trim()).filter(Boolean);
  const result = await api("/pipeline", "POST", {
    title,
    body,
    agents,
    source:    source || "github",
    sourceRef: ref || null,
    workdir:   workdir || null,
  });
  process.stdout.write(result.id + "\n");
  break;
}

case "task-json": {
  // id
  const id = args[1];
  if (!id) { process.stderr.write("Usage: task-json <id>\n"); process.exit(1); }
  const data = await api(`/tasks/${id}`);
  // Full JSON on stdout — parsed by GitHub Actions polling job
  process.stdout.write(JSON.stringify(data) + "\n");
  break;
}

*/

// ── Standalone version ────────────────────────────────────────────────────────
// Use this if you prefer not to modify cli.js:
//   node cli-additions.js add-raw "title" "body" 5 senior github run-123 ~/projects/my-app

const BASE = `http://localhost:${process.env.SUPERVISOR_PORT || 3100}`;
const args = process.argv.slice(2);
const cmd  = args[0];

async function api(path, method = "GET", body = null) {
  const opts = { method, headers: { "Content-Type": "application/json" } };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${BASE}${path}`, opts);
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(`API ${res.status}: ${err.error || res.statusText}`);
  }
  return res.json();
}

try {
  switch (cmd) {
    case "add-raw": {
      const [,, title, body, priority, agentId, source, ref, workdir] = args;
      if (!title || !body) {
        process.stderr.write("Usage: add-raw <title> <body> <priority> <agentId> <source> <ref> <workdir>\n");
        process.exit(1);
      }
      const result = await api("/tasks", "POST", {
        title,
        body,
        agentId:   agentId && agentId !== "" ? agentId : null,
        priority:  parseInt(priority || "5"),
        source:    source || "github",
        sourceRef: ref || null,
        workdir:   workdir || null,
      });
      process.stdout.write(result.id + "\n");
      break;
    }

    case "pipeline-raw": {
      const [,, title, body, agentsCsv, ref, source, workdir] = args;
      if (!title || !body || !agentsCsv) {
        process.stderr.write("Usage: pipeline-raw <title> <body> <agents_csv> <ref> <source> <workdir>\n");
        process.exit(1);
      }
      const agents = agentsCsv.split(",").map(s => s.trim()).filter(Boolean);
      const result = await api("/pipeline", "POST", {
        title,
        body,
        agents,
        source:    source || "github",
        sourceRef: ref || null,
        workdir:   workdir || null,
      });
      process.stdout.write(result.id + "\n");
      break;
    }

    case "task-json": {
      const id = args[1];
      if (!id) { process.stderr.write("Usage: task-json <id>\n"); process.exit(1); }
      const data = await api(`/tasks/${id}`);
      process.stdout.write(JSON.stringify(data) + "\n");
      break;
    }

    default:
      process.stderr.write(`Unknown command: ${cmd}\nAvailable: add-raw, pipeline-raw, task-json\n`);
      process.exit(1);
  }
} catch (e) {
  if (e.code === "ECONNREFUSED") {
    process.stderr.write(`Supervisor not running at ${BASE}\nStart it: pm2 start pm2.config.cjs\n`);
  } else {
    process.stderr.write(e.message + "\n");
  }
  process.exit(1);
}
