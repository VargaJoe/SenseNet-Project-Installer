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
  // This sequence starts several real PowerShell workers and reloads the
  // configuration repeatedly. Allow their combined time on a busy runner;
  // individual readiness and run assertions retain their own bounded waits.
  test.setTimeout(180_000);
  const name = `Browser acceptance ${Date.now()}`;
  await page.goto(`/#token=${token}`);
  await expect(page.getByTestId("management-ready")).toBeVisible();
  expect(new URL(page.url()).hash).toBe("");
  const cookies = await context.cookies();
  expect(
    cookies.find((c) => c.name.startsWith("PlotManager.Session.")),
  ).toMatchObject({
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
    .getByRole("textbox", { name: /^Output file on runner\b/ })
    .fill("browser-acceptance.txt");
  await page.getByRole("button", { name: "Continue to settings →" }).click();
  await page
    .getByRole("textbox", { name: /^File content\b/ })
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
    .poll(() => new URL(page.url()).searchParams.get("run"), { timeout: 60_000 })
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
  // Seed exact raw tokens without parsing them through the test's native Number.
  await editor.fill(
    JSON.stringify(layerData, null, 2).replace(
      /\}\s*$/,
      ',"Precise":{"integer":9007199254740993,"decimal":0.12345678901234567890123456789}}',
    ),
  );
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
  const preciseResponse = await page.request.get(
    `/api/projects/${projectId}/layers/project`,
  );
  const preciseRaw = await preciseResponse.text();
  expect(preciseRaw).toMatch(/"integer"\s*:\s*9007199254740993/);
  expect(preciseRaw).toMatch(
    /"decimal"\s*:\s*0\.12345678901234567890123456789/,
  );
  await page.locator(".invocation-main").filter({ hasText: "compose" }).click();
  await page
    .getByRole("button", { name: "Run invocation", exact: true })
    .click();
  await expect
    .poll(() => new URL(page.url()).searchParams.get("run"), { timeout: 60_000 })
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
    .getByRole("navigation", { name: "Main navigation" })
    .getByRole("button", { name: "Guided setup", exact: true })
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

test("saved wizard answers survive environment and project changes without resetting their configuration", async ({
  page,
}) => {
  const name = `Saved wizard answers ${Date.now()}`;
  const answers = {
    Target: "my-saved-target.txt",
    Message: "Keep the operator's saved answers after reopening the project",
  };
  const navigation = page.getByRole("navigation", { name: "Main navigation" });
  await page.goto(`/#token=${token}`);
  await expect(page.getByTestId("management-ready")).toBeVisible();
  await page.getByLabel("Project name", { exact: true }).fill(name);
  await page
    .getByRole("button", { name: "+ Create project", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Generic file installer" }),
  ).toBeVisible();
  const projectId = new URL(page.url()).searchParams.get("project")!;
  const target = page.getByRole("textbox", { name: /^Output file on runner\b/ });
  const message = page.getByRole("textbox", { name: /^File content\b/ });
  await target.fill(answers.Target);
  await page.getByRole("button", { name: "Continue to settings →" }).click();
  await message.fill(answers.Message);
  await page.getByRole("button", { name: "Save answers →" }).click();
  await expect(
    page.getByRole("heading", { name: "Inspect before execution" }),
  ).toBeVisible();

  // The saved project layer, rather than the wizard descriptor's defaults,
  // must supply the next visit's form values. Creating an empty environment
  // changes the selected layer without changing the inherited project values.
  await navigation.getByRole("button", { name: "Workspace", exact: true }).click();
  await page.getByLabel("Add environment", { exact: true }).fill("staging");
  await page
    .getByRole("button", { name: "Create environment", exact: true })
    .click();
  await expect(page.getByLabel("Active environment")).toHaveValue("staging");
  await navigation
    .getByRole("button", { name: "Guided setup", exact: true })
    .click();
  await expect(target).toHaveValue(answers.Target);
  await page.getByRole("button", { name: "Continue to settings →" }).click();
  await expect(message).toHaveValue(answers.Message);

  await page.getByLabel("Active environment").selectOption("development");
  await expect(target).toHaveValue(answers.Target);
  await page.getByRole("button", { name: "Continue to settings →" }).click();
  await expect(message).toHaveValue(answers.Message);

  await navigation.getByRole("button", { name: "Workspace", exact: true }).click();
  await page
    .getByLabel("Project name", { exact: true })
    .fill(`Other wizard project ${Date.now()}`);
  await page
    .getByRole("button", { name: "+ Create project", exact: true })
    .click();
  await expect
    .poll(() => new URL(page.url()).searchParams.get("project"))
    .not.toBe(projectId);
  await navigation.getByRole("button", { name: "Workspace", exact: true }).click();
  await page.locator(".project-item").filter({ hasText: name }).click();
  await expect
    .poll(() => new URL(page.url()).searchParams.get("project"))
    .toBe(projectId);
  await navigation
    .getByRole("button", { name: "Guided setup", exact: true })
    .click();
  await expect(target).toHaveValue(answers.Target);
  await page.getByRole("button", { name: "Continue to settings →" }).click();
  await expect(message).toHaveValue(answers.Message);

  // Saving an unchanged, reopened form must not replace the saved answers
  // with hello.txt / Hello from Plot Manager. No plot execution is needed.
  await page.getByRole("button", { name: "Save answers →" }).click();
  await expect(
    page.getByRole("heading", { name: "Inspect before execution" }),
  ).toBeVisible();
  const saved = await json<{ data: { Sample: typeof answers } }>(
    page,
    `/api/projects/${projectId}/layers/project`,
  );
  expect(saved.data.Sample).toEqual(answers);
  expect(
    (await json<{ runs: unknown[] }>(page, `/api/projects/${projectId}/runs`))
      .runs,
  ).toHaveLength(0);
});

test("portable definition draft survives Workspace to Plot editor navigation and saves the same draft", async ({
  page,
}) => {
  const name = `Definition draft navigation ${Date.now()}`;
  const navigation = page.getByRole("navigation", { name: "Main navigation" });
  await page.goto(`/#token=${token}`);
  await expect(page.getByTestId("management-ready")).toBeVisible();
  await page.getByLabel("Project name", { exact: true }).fill(name);
  await page.getByLabel("Include the generic guided installation").uncheck();
  await page
    .getByRole("button", { name: "+ Create project", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: `Continue with ${name}`, exact: true }),
  ).toBeVisible();
  const projectId = new URL(page.url()).searchParams.get("project")!;
  const editor = page.getByLabel("Portable project definition JSON");
  const summary = page
    .locator("summary")
    .filter({ hasText: "Edit portable project definition" });
  await summary.click();
  await expect(editor).not.toHaveValue("");
  const original = JSON.parse(await editor.inputValue());
  const draft = {
    ...original,
    description: "This unsaved definition must survive changing the visible page",
    ReviewMetadata: { retained: true, attempts: 0 },
  };
  const draftText = JSON.stringify(draft, null, 2);
  await editor.fill(draftText);

  await navigation
    .getByRole("button", { name: "Plot editor", exact: true })
    .click();
  await navigation.getByRole("button", { name: "Workspace", exact: true }).click();
  // A retained editor may keep its <details> open; a remounted one may not.
  // The regression assertion concerns the text, independently of expansion.
  if (!(await editor.isVisible())) await summary.click();
  await expect(editor).toHaveValue(draftText);
  const beforeSave = await json<{ data: typeof draft }>(
    page,
    `/api/projects/${projectId}/definition`,
  );
  expect(beforeSave.data).toEqual(original);
  await page.getByRole("button", { name: "Save definition", exact: true }).click();
  await expect(
    page.getByRole("status").filter({ hasText: "Portable project definition saved" }),
  ).toBeVisible();
  const saved = await json<{ data: typeof draft }>(
    page,
    `/api/projects/${projectId}/definition`,
  );
  expect(saved.data).toEqual(draft);
  await expect(page.getByRole("alert")).toHaveCount(0);
});

test("invalid JSON parameters keep their text and block saving or execution while a sibling parameter changes", async ({
  page,
}) => {
  await page.goto(`/#token=${token}`);
  await expect(page.getByTestId("management-ready")).toBeVisible();
  await page
    .getByLabel("Project name", { exact: true })
    .fill(`Unapplied parameter edits ${Date.now()}`);
  await page
    .getByRole("button", { name: "+ Create project", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Generic file installer" }),
  ).toBeVisible();
  const projectId = new URL(page.url()).searchParams.get("project")!;
  await page
    .getByRole("navigation", { name: "Main navigation" })
    .getByRole("button", { name: "Plot editor", exact: true })
    .click();
  await page.locator(".invocation-main").filter({ hasText: "compose" }).click();
  const items = page.getByLabel("Items JSON value", { exact: true });
  const separator = page.getByLabel("Separator", { exact: true });
  const save = page.getByRole("button", { name: "Save layer", exact: true });
  const preflight = page.getByRole("button", {
    name: "Preflight plot",
    exact: true,
  });
  const run = page.getByRole("button", { name: "▶ Run plot", exact: true });

  // Start with a real applied edit, so the Save button would otherwise be
  // enabled. Merely leaving the initial layer clean could mask the regression.
  await items.fill('["first applied value"]');
  await items.blur();
  await expect(save).toBeEnabled();

  const invalidText = '["unfinished"';
  await items.fill(invalidText);
  await items.blur();
  await expect(items).toHaveValue(invalidText);
  await expect(save).toBeDisabled();
  await expect(preflight).toBeDisabled();
  await expect(run).toBeDisabled();

  // Editing Separator clones the invocation and causes a parent rerender.
  // Items must retain its local invalid draft across that new object identity.
  await separator.fill(" / ");
  await separator.blur();
  await expect(items).toHaveValue(invalidText);
  await expect(save).toBeDisabled();
  await expect(preflight).toBeDisabled();
  await expect(run).toBeDisabled();

  const finalItems = ["persisted", "values"];
  await items.fill(JSON.stringify(finalItems));
  await items.blur();
  await expect(save).toBeEnabled();
  await save.click();
  await expect(
    page.getByRole("status").filter({ hasText: "Saved only" }),
  ).toBeVisible();
  const persisted = await json<{
    data: {
      Plots: {
        install: {
          Steps: {
            Id: string;
            With: { Items?: string[]; Separator?: string };
          }[];
        };
      };
    };
  }>(page, `/api/projects/${projectId}/layers/project`);
  expect(
    persisted.data.Plots.install.Steps.find((step) => step.Id === "compose")
      ?.With,
  ).toEqual({ Items: finalItems, Separator: " / " });
  await expect(preflight).toBeEnabled();
  await expect(run).toBeEnabled();
});
