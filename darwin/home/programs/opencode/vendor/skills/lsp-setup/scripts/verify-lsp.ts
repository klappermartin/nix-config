#!/usr/bin/env bun
// Modified standalone adapter: verify via the installed MCP CLI, not monorepo imports.
import { spawn } from "node:child_process"
import { existsSync } from "node:fs"
import { resolve } from "node:path"
import { createInterface } from "node:readline"

const args = process.argv.slice(2)
const file = args.find((arg) => !arg.startsWith("--"))
const timeout = Number(args.find((arg) => arg.startsWith("--timeout="))?.split("=")[1] ?? 60000)
if (!file || !existsSync(file) || !Number.isFinite(timeout) || timeout <= 0) {
  console.error("Usage: bun verify-lsp.ts <existing-file> [--timeout=60000]")
  process.exit(2)
}

const child = spawn("lsp-tools-mcp", [], { stdio: ["pipe", "pipe", "inherit"] })
const lines = createInterface({ input: child.stdout })
let finished = false
const finish = (code: number, message: string) => {
  if (finished) return
  finished = true
  clearTimeout(timer)
  console.log(message)
  process.exitCode = code
  lines.close()
  child.stdin.end()
  child.kill("SIGTERM")
}
const timer = setTimeout(() => finish(1, "FAIL: diagnostics timed out"), timeout)
const send = (message: object) => child.stdin.write(JSON.stringify({ jsonrpc: "2.0", ...message }) + "\n")
child.on("error", (error) => finish(1, `FAIL: ${error.message}`))
child.on("exit", () => { if (!finished) finish(1, "FAIL: MCP server exited before diagnostics") })
child.stdin.on("error", (error) => finish(1, `FAIL: ${error.message}`))
lines.on("line", (line) => {
  try {
    const message = JSON.parse(line)
    if (message.error) return finish(1, `FAIL: ${JSON.stringify(message.error)}`)
    if (message.id === 1) {
      send({ method: "notifications/initialized" })
      send({ id: 2, method: "tools/call", params: {
        name: "diagnostics", arguments: { filePath: resolve(file), severity: "all" },
      } })
    } else if (message.id === 2) {
      const result = message.result
      const text = (result.content ?? []).map((part: { text?: string }) => part.text ?? "").join("\n")
      // Tool errors may carry either the MCP flag or structured diagnostic details.
      const failed = result.isError || result.details?.errorKind || /missing_dependency|not installed|not configured|no language server/i.test(text)
      finish(failed ? 1 : 0, `${failed ? "FAIL" : "OK"}: ${text}`)
    }
  } catch (error) {
    finish(1, `FAIL: invalid MCP response: ${String(error)}`)
  }
})
send({ id: 1, method: "initialize", params: {
  protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "verify-lsp", version: "1" },
} })
