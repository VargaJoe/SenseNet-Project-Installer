import { defineConfig } from "@playwright/test";

if (!process.env.PLOTMANAGER_E2E_URL || !process.env.PLOTMANAGER_E2E_TOKEN)
  throw new Error(
    "Start an isolated management service with scripts/Test-Management.ps1, or set PLOTMANAGER_E2E_URL and PLOTMANAGER_E2E_TOKEN.",
  );
export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  workers: 1,
  timeout: 120_000,
  expect: { timeout: 20_000 },
  reporter: [["list"]],
  use: {
    baseURL: process.env.PLOTMANAGER_E2E_URL,
    browserName: "chromium",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
});
