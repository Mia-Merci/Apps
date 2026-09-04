#!/usr/bin/env node

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const authPath = process.env.CODEX_HOME
  ? join(process.env.CODEX_HOME, "auth.json")
  : join(homedir(), ".codex", "auth.json");

const auth = JSON.parse(readFileSync(authPath, "utf8"));
const tokens = auth.tokens || auth;
const accessToken = tokens.access_token || tokens.accessToken;
const accountID = tokens.account_id || tokens.accountId || accountIDFromJWT(accessToken);

if (!accessToken) {
  console.error("Codex login expired. Please sign in again.");
  process.exit(1);
}

const headers = {
  authorization: `Bearer ${accessToken}`,
  accept: "application/json",
  originator: "Codex Desktop",
  "OAI-Product-Sku": "CODEX",
};

if (accountID) {
  headers["ChatGPT-Account-Id"] = accountID;
}

let response;
try {
  response = await fetch("https://chatgpt.com/backend-api/wham/usage", {
    headers,
  });
} catch {
  console.error("Network unavailable. It will retry automatically.");
  process.exit(1);
}

if (!response.ok) {
  if (response.status === 401 || response.status === 403) {
    console.error("Codex login expired. Please sign in again.");
  } else {
    console.error(`Quota service returned HTTP ${response.status}.`);
  }
  process.exit(1);
}

const usage = await response.json();
const rateLimit = usage.rate_limit || usage.rateLimit || usage;
const shortWindow = parseWindow(
  findWindow(
    rateLimit,
    [
      "primary_window",
      "primaryWindow",
      "short_window",
      "shortWindow",
      "five_hour_window",
      "fiveHourWindow",
      "5h",
      "primary",
    ],
    18000,
  ),
);
const weeklyWindow = parseWindow(
  findWindow(
    rateLimit,
    [
      "secondary_window",
      "secondaryWindow",
      "weekly_window",
      "weeklyWindow",
      "week_window",
      "weekWindow",
      "weekly",
      "secondary",
      "primary_window",
      "primaryWindow",
      "primary",
    ],
    604800,
  ),
);
const displayWindow = [shortWindow, weeklyWindow]
  .filter(Boolean)
  .sort((a, b) => a.remainingPercent - b.remainingPercent)[0];

if (!displayWindow) {
  console.error("Quota response does not contain a recognized usage window.");
  process.exit(1);
}

console.log(
  JSON.stringify(
    {
      usedPercent: Math.round(100 - displayWindow.remainingPercent),
      remainingPercent: Math.round(displayWindow.remainingPercent),
      resetsAt: displayWindow.resetsAt,
      windowDurationMins: Math.round(displayWindow.windowSeconds / 60),
      shortRemainingPercent: shortWindow?.remainingPercent ?? null,
      weeklyRemainingPercent: weeklyWindow?.remainingPercent ?? null,
    },
    null,
    2,
  ),
);

function findWindow(rateLimit, names, expectedSeconds) {
  for (const name of names) {
    const value = rateLimit?.[name];
    const window = parseWindow(value);
    if (
      window &&
      (window.windowSeconds === 0 ||
        Math.abs(window.windowSeconds - expectedSeconds) <= 60)
    ) {
      return value;
    }
  }

  for (const key of ["windows", "limit_windows", "limitWindows", "limits", "buckets"]) {
    const items = rateLimit?.[key];
    if (!Array.isArray(items)) continue;

    for (const item of items) {
      const window = parseWindow(item);
      if (!window) continue;

      const durationMatches = Math.abs(window.windowSeconds - expectedSeconds) <= 60;
      const label = String(item.name || item.type || item.id || item.window || item.label || "")
        .toLowerCase();
      const nameMatches = names.some((name) => {
        const lower = name.toLowerCase();
        return label === lower || label.includes(lower);
      });

      if (durationMatches || nameMatches) {
        return item;
      }
    }
  }

  return null;
}

function parseWindow(value) {
  if (!value || typeof value !== "object") return null;

  const remaining = numberWithKey(value, [
    "remaining_percent",
    "remainingPercent",
    "remaining_pct",
    "remainingPct",
    "remaining_ratio",
    "remainingRatio",
    "remaining",
  ]);
  const used = numberWithKey(value, [
    "used_percent",
    "usedPercent",
    "used_pct",
    "usedPct",
    "used_ratio",
    "usedRatio",
    "utilization",
    "used",
  ]);

  let remainingPercent;
  if (remaining) {
    remainingPercent = scaleIfRatio(remaining.key, remaining.value);
  } else if (used) {
    remainingPercent = 100 - scaleIfRatio(used.key, used.value);
  } else {
    return null;
  }

  return {
    remainingPercent: Math.max(0, Math.min(100, remainingPercent)),
    resetsAt: timestamp(value, [
      "reset_at",
      "resetAt",
      "resets_at",
      "resetsAt",
      "reset_time",
      "resetTime",
    ]),
    windowSeconds:
      integer(value, [
        "limit_window_seconds",
        "limitWindowSeconds",
        "window_seconds",
        "windowSeconds",
        "duration_seconds",
        "durationSeconds",
        "period_seconds",
        "periodSeconds",
      ]) || 0,
  };
}

function numberWithKey(value, keys) {
  for (const key of keys) {
    const item = value[key];
    if (typeof item === "number") {
      return { key, value: item };
    }
  }
  return null;
}

function integer(value, keys) {
  for (const key of keys) {
    const item = value[key];
    if (Number.isInteger(item)) {
      return item;
    }
  }
  return null;
}

function timestamp(value, keys) {
  for (const key of keys) {
    const item = value[key];
    if (typeof item === "number") {
      return new Date(item * 1000).toISOString();
    }
    if (typeof item === "string") {
      return item;
    }
  }
  return null;
}

function scaleIfRatio(key, value) {
  if (
    key.includes("ratio") ||
    key === "utilization" ||
    (!key.includes("percent") && !key.includes("pct") && value <= 1)
  ) {
    return value * 100;
  }
  return value;
}

function accountIDFromJWT(token) {
  if (!token) return null;
  const payload = token.split(".")[1];
  if (!payload) return null;

  const json = JSON.parse(Buffer.from(payload, "base64url").toString("utf8"));
  return (
    json["https://api.openai.com/auth.chatgpt_account_id"] ||
    json.chatgpt_account_id ||
    null
  );
}
