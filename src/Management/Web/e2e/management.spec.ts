import { test, expect, type Page } from "@playwright/test";
import { readFile, rm } from "node:fs/promises";
import path from "node:path";

const token = process.env.PLOTMANAGER_E2E_TOKEN!;
async function json<T>(page: Page, url: string): Promise<T> {
  const result = await page.request.get(url);
  expect(result.ok()).toBeTruthy();
  return result.json();
}
async function waitForRun(page: Page, projectId: string, id: string) {
  await expect
    .poll(
      async () =>
        (
          await json<{ status: string }>(
            page,
            `/api/projects/${projectId}/runs/${id}`,
          )
        ).status,
      { timeout: 60_000 },
    )
    .toBe("Succeeded");
}

test("fresh wizard, real full/single execution, reorder preflight, typed layer roundtrip and durable reconnect", async ({
  page,
  context,
}) => {
  const name = `Browser acceptance ${Date.now()}`;
  await page.goto(`/#token=${token}`);
  await expect(page.getByTestId("management-ready")).toBeVisible();
  expect(new URL(page.url()).hash).toBe("");
  const cookies = await context.cookies();
  expect(cookies.find((c) => c.name === "PlotManager.Session")).toMatchObject({
    httpOnly: true,
    sameSite: "Strict",
  });
  expect(
    await page.evaluate(() => [localStorage.length, sessionStorage.length]),
  ).toEqual([0, 0]);
  await page.getByLabel("Project name", { exact: true }).fill(name);
  await page
    .getByRole("button", { name: "+ Create project", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Generic file installer" }),
  ).toBeVisible();
  await page
    .getByLabel("Output file on runner", { exact: false })
    .fill("browser-acceptance.txt");
  await page.getByRole("button", { name: "Continue to settings →" }).click();
  await page
    .getByLabel("File content", { exact: false })
    .fill("A real browser-triggered worker result");
  await page.getByRole("button", { name: "Save answers →" }).click();
  await page
    .getByRole("button", { name: "Run static preflight", exact: true })
    .click();
  await page.getByRole("button", { name: "Continue to run →" }).click();
  await page
    .getByRole("button", { name: "▶ Run sample installation", exact: true })
    .click();
  const projectId = new URL(page.url()).searchParams.get("project")!;
  await expect
    .poll(() => new URL(page.url()).searchParams.get("run"))
    .toBeTruthy();
  const fullRunId = new URL(page.url()).searchParams.get("run")!;
  await waitForRun(page, projectId, fullRunId);
  const project = await json<{ directory: string }>(
    page,
    `/api/projects/${projectId}`,
  );
  const outputFile = path.join(project.directory, "browser-acceptance.txt");
  expect(await readFile(outputFile, "utf8")).toBe(
    "A real browser-triggered worker result",
  );
  await page
    .getByRole("button", { name: "Open run history", exact: true })
    .click();
  await expect(page.locator(".event-log")).toContainText("StepStarted");
  const stableUrl = page.url();
  await page.reload();
  await expect(page.getByTestId("management-ready")).toBeVisible();
  await page.getByRole("button", { name: /Run history/, exact: false }).click();
  await expect(page.locator(".run-metadata")).toContainText(fullRunId);
  await expect(page.locator(".event-log")).toContainText("StepCompleted");

  await page
    .getByRole("button", { name: "Configuration", exact: false })
    .first()
    .click();
  const editor = page.getByLabel("Editable layer JSON");
  const layerData = JSON.parse(await editor.inputValue());
  layerData.Extension = {
    nil: null,
    disabled: false,
    zero: 0,
    empty: [],
    unknown: { retained: true },
  };
  await editor.fill(JSON.stringify(layerData, null, 2));
  await page.getByRole("button", { name: "Save layer", exact: true }).click();
  await expect(
    page.getByRole("status").filter({ hasText: "Saved only" }),
  ).toBeVisible();
  const roundtrip = await json<{ data: unknown }>(
    page,
    `/api/projects/${projectId}/layers/project`,
  );
  expect(roundtrip.data).toMatchObject({ Extension: layerData.Extension });

  await page.getByRole("button", { name: "Plot editor", exact: false }).click();
  await page
    .getByRole("button", { name: "Move save earlier", exact: true })
    .click();
  await page.getByRole("button", { name: "Save layer", exact: true }).click();
  await page
    .getByRole("button", { name: "Preflight plot", exact: true })
    .click();
  await expect(page.getByRole("alert")).toContainText("earlier");
  expect(
    (await json<{ runs: unknown[] }>(page, `/api/projects/${projectId}/runs`))
      .runs,
  ).toHaveLength(1);
  await page
    .getByRole("button", { name: "Move save later", exact: true })
    .click();
  await page.getByRole("button", { name: "Save layer", exact: true }).click();
  await page.locator(".invocation-main").filter({ hasText: "compose" }).click();
  await page
    .getByRole("button", { name: "Run invocation", exact: true })
    .click();
  await expect
    .poll(() => new URL(page.url()).searchParams.get("run"))
    .not.toBe(fullRunId);
  const singleRunId = new URL(page.url()).searchParams.get("run")!;
  await waitForRun(page, projectId, singleRunId);
  const single = await json<{ invocationId: string; steps: { id: string }[] }>(
    page,
    `/api/projects/${projectId}/runs/${singleRunId}`,
  );
  expect(single.invocationId).toBe("compose");
  expect(single.steps.map((step) => step.id)).toEqual(["compose"]);

  // All resources are this test's isolated project; the orchestrator removes its root.
  await rm(outputFile, { force: true });
  await page.goto(stableUrl);
  await page.getByRole("button", { name: /Run history/, exact: false }).click();
  await expect(page.locator(".run-metadata")).toContainText(fullRunId);
});

test("opens a blank portable project without a wizard or environment layer", async ({
  page,
}) => {
  await page.goto(`/#token=${token}`);
  await expect(page.getByTestId("management-ready")).toBeVisible();
  const name = `Blank browser project ${Date.now()}`;
  await page.getByLabel("Project name", { exact: true }).fill(name);
  await page.getByLabel("Include the generic guided installation").uncheck();
  await page
    .getByRole("button", { name: "+ Create project", exact: true })
    .click();
  await expect
    .poll(() => new URL(page.url()).searchParams.get("project"))
    .toBeTruthy();
  const projectId = new URL(page.url()).searchParams.get("project")!;
  const definition = await json<{
    etag: string;
    data: { configuration: { environments?: unknown } };
  }>(page, `/api/projects/${projectId}/definition`);
  delete definition.data.configuration.environments;
  const saved = await page.request.put(
    `/api/projects/${projectId}/definition`,
    { headers: { "X-Plot-Request": "1" }, data: definition },
  );
  expect(saved.ok()).toBeTruthy();
  await page.reload();
  await expect(page.getByTestId("management-ready")).toBeVisible();
  await expect(page.getByLabel("Active environment")).toHaveValue("");
  await page
    .getByRole("button", { name: "Guided setup", exact: false })
    .click();
  await expect(
    page.getByRole("heading", { name: "No guided form in this project" }),
  ).toBeVisible();
  await page
    .getByRole("button", { name: "Configuration", exact: false })
    .first()
    .click();
  await expect(page.getByLabel("Editable layer JSON")).toHaveValue("{}");
  await expect(page.getByRole("alert")).toHaveCount(0);
});
