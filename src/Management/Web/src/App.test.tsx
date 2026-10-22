import {
  cleanup,
  render,
  screen,
  waitFor,
  fireEvent,
  within,
} from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import App from "./App";

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  history.replaceState(null, "", "/");
});

describe("managed run session lifecycle", () => {
  it("rejects a duplicate plot name without replacing existing steps or dirtying the source layer", async () => {
    history.replaceState(null, "", "/?project=p&environment=");
    const configuration = {
      Plots: {
        INSTALL: {
          Steps: [
            { Id: "keep", Step: "text.join", With: { Items: ["retained"] } },
          ],
        },
      },
    };
    const responses: Record<string, unknown> = {
      "/api/session": { authenticated: true, user: "operator", mode: "local" },
      "/api/runner": {
        id: "runner",
        displayName: "Test runner",
        os: "Test OS",
        identity: "isolated",
        mode: "local",
        protocolVersion: 1,
        powerShell: "pwsh",
      },
      "/api/catalog": {
        engine: {
          Steps: [
            {
              Id: "text.join",
              Package: "text",
              Version: "1.0.0",
              Parameters: { Items: { Type: "array", Required: true } },
            },
          ],
        },
      },
      "/api/projects": {
        projects: [
          {
            id: "p",
            name: "Case insensitive project",
            directory: "/isolated/project",
            environments: [],
            definition: {},
          },
        ],
      },
      "/api/projects/p/layers?environment=": {
        layers: [{ id: "project", label: "Project", path: "project.json" }],
      },
      "/api/projects/p/configuration?environment=": {
        engine: {
          Configuration: configuration,
          Sources: { "Plots.INSTALL.Steps": "/isolated/project/project.json" },
          Layers: [
            { Path: "/isolated/project/project.json", Data: configuration },
          ],
        },
      },
      "/api/projects/p/layers/project": {
        id: "project",
        path: "project.json",
        etag: "one",
        data: configuration,
      },
      "/api/projects/p/runs": { runs: [] },
      "/api/projects/p/definition": { etag: "def", data: {} },
    };
    vi.stubGlobal(
      "fetch",
      vi.fn(async (url: string) => {
        if (url.endsWith("/wizard"))
          return new Response('{"error":"No wizard"}', { status: 404 });
        if (!Object.hasOwn(responses, url))
          throw new Error(`Unexpected API request: ${url}`);
        return new Response(JSON.stringify(responses[url]));
      }),
    );
    vi.spyOn(window, "prompt").mockReturnValue("install");
    render(<App />);
    await waitFor(() =>
      expect(screen.getByTestId("management-ready")).toBeVisible(),
    );
    fireEvent.click(
      within(
        screen.getByRole("navigation", { name: "Main navigation" }),
      ).getByRole("button", { name: "Plot editor" }),
    );
    await waitFor(() =>
      expect(
        screen.getByRole("button", { name: "+ New plot" }),
      ).toBeEnabled(),
    );
    fireEvent.click(
      screen.getByRole("button", { name: "+ New plot" }),
    );
    expect(screen.getByRole("alert")).toHaveTextContent("already exists");
    expect(screen.getByLabelText("Selected plot")).toHaveValue("INSTALL");
    expect(
      screen.getByRole("button", { name: "Save layer" }),
    ).toBeDisabled();
    expect(
      screen.getByRole("button", { name: "Move keep earlier" }),
    ).toBeVisible();
  });
  it("stops polling on session expiry, opens sign-in, and retains the durable run URL", async () => {
    history.replaceState(null, "", "/?project=p&environment=&run=r");
    const project = {
      id: "p",
      name: "Existing portable project",
      directory: "/isolated/project",
      environments: [],
      definition: {},
    };
    const run = {
      id: "r",
      projectId: "p",
      plot: "install",
      environment: "",
      whatIf: false,
      status: "Running",
      createdAt: "2026-10-21T10:00:00Z",
    };
    const fetch = vi.fn(async (url: string) => {
      let body: unknown;
      if (url === "/api/session")
        body = { authenticated: true, user: "operator", mode: "local" };
      else if (url === "/api/runner")
        body = {
          id: "runner",
          displayName: "Test runner",
          os: "Test OS",
          identity: "isolated",
          mode: "local",
          protocolVersion: 1,
          powerShell: "pwsh",
        };
      else if (url === "/api/catalog") body = { engine: { Steps: [] } };
      else if (url === "/api/projects") body = { projects: [project] };
      else if (url === "/api/projects/p/layers?environment=")
        body = {
          layers: [{ id: "project", label: "Project", path: "project.json" }],
        };
      else if (url === "/api/projects/p/configuration?environment=")
        body = {
          engine: {
            Configuration: {},
            Sources: {},
            Layers: [{ Path: "/isolated/project/project.json", Data: {} }],
          },
        };
      else if (url === "/api/projects/p/layers/project")
        body = { id: "project", path: "project.json", etag: "one", data: {} };
      else if (url === "/api/projects/p/runs") body = { runs: [run] };
      else if (url === "/api/projects/p/wizard")
        return new Response('{"error":"No wizard"}', { status: 404 });
      else if (url === "/api/projects/p/definition")
        body = { etag: "def", data: {} };
      else if (url.startsWith("/api/projects/p/runs/r"))
        return new Response(
          '{"error":"Authentication required.","code":"unauthorized"}',
          { status: 401 },
        );
      else throw new Error(`Unexpected API request: ${url}`);
      return new Response(JSON.stringify(body));
    });
    vi.stubGlobal("fetch", fetch);
    render(<App />);
    await waitFor(() =>
      expect(screen.getByRole("alert")).toHaveTextContent(
        "Your session expired",
      ),
    );
    expect(screen.getByLabelText("Access token")).toBeVisible();
    expect(location.search).toContain("run=r");
    expect(
      fetch.mock.calls.filter(([url]) => url === "/api/projects/p/runs/r"),
    ).toHaveLength(1);
  });
});

function editingFixture(reference = false) {
  history.replaceState(null, "", "/?project=p&environment=development");
  const projects = ["p", "q"].map((id) => ({
    id, name: `Project ${id}`, directory: `/isolated/${id}`,
    environments: ["development", "staging"], definition: {},
  }));
  let savedMessage = "Saved message";
  const config = (environment = "development") => ({
    Values: {
      Target: reference ? { $env: "PRIVATE_TARGET" } : `${environment}-saved.txt`,
      Message: savedMessage, Enabled: false, Count: 0, Items: [], Nil: null,
    },
    Plots: { install: { Steps: [
      { Id: "compose", Step: "text.join", With: { Items: ["kept"], Count: 2 } },
      { Id: "other", Step: "text.join", With: { Items: [] } },
    ] } },
  });
  let definition = { name: "Original", formatVersion: 1 };
  const wizard = {
    title: "Example setup", description: "Test wizard", plot: "install", layer: "project",
    groups: [
      { id: "target", title: "Target", fields: [
        { key: "target", label: "Target file", type: "string", default: "default.txt", settingPath: "values.target" },
      ] },
      { id: "settings", title: "Settings", fields: [
        { key: "message", label: "Message", type: "string", default: "Default message", settingPath: "Values.Message" },
        { key: "enabled", label: "Enabled", type: "bool", default: true, settingPath: "Values.Enabled" },
        { key: "count", label: "Count", type: "int", default: 7, settingPath: "Values.Count" },
        { key: "items", label: "Items", type: "array", default: ["default"], settingPath: "Values.Items" },
        { key: "nil", label: "Nullable", type: "string", default: "fallback", settingPath: "Values.Nil" },
        { key: "missing", label: "Missing", type: "string", default: "fallback", settingPath: "Values.Missing" },
      ] },
    ],
  };
  const fetch = vi.fn(async (url: string, init?: RequestInit) => {
    let body: unknown;
    if (url === "/api/session") body = { authenticated: true, user: "operator", mode: "local" };
    else if (url === "/api/runner") body = { id: "test", displayName: "Test runner", identity: "isolated", os: "Test OS", mode: "local" };
    else if (url === "/api/catalog") body = { engine: { Steps: [{ Id: "text.join", Parameters: { Items: { Type: "array" }, Count: { Type: "int" } } }] } };
    else if (url === "/api/projects") body = { projects };
    else if (/^\/api\/projects\/[pq]$/.test(url)) body = projects.find((project) => url.endsWith(`/${project.id}`));
    else if (/\/definition$/.test(url)) {
      if (init?.method === "PUT") definition = JSON.parse(String(init.body)).data;
      body = { etag: "def", data: definition };
    } else if (/\/wizard$/.test(url)) body = init?.method === "POST" ? {} : wizard;
    else if (/\/layers\?/.test(url)) body = { layers: [{ id: "project", label: "Project", path: "project.json" }] };
    else if (/\/configuration\?/.test(url)) {
      const environment = new URL(url, "http://localhost").searchParams.get("environment") || "development";
      body = { engine: { Configuration: config(environment), Sources: { "Plots.install.Steps": "/isolated/project.json" }, Layers: [{ Path: "/isolated/project.json" }] } };
    } else if (/\/layers\/project$/.test(url)) {
      if (init?.method === "PUT") savedMessage = JSON.parse(String(init.body)).data.Values.Message;
      body = { id: "project", label: "Project", path: "project.json", etag: "one", data: config() };
    }
    else if (/\/runs$/.test(url)) body = { runs: [] };
    else throw new Error(`Unexpected API request: ${url}`);
    return new Response(JSON.stringify(body));
  });
  vi.stubGlobal("fetch", fetch);
  return fetch;
}

async function editingApp(view?: string) {
  render(<App />);
  await screen.findByText("/isolated/p", { selector: "code" });
  await waitFor(() => expect(screen.getByLabelText("Portable project definition JSON")).toHaveValue('{\n  "name": "Original",\n  "formatVersion": 1\n}'));
  if (view) fireEvent.click(within(screen.getByRole("navigation", { name: "Main navigation" })).getByRole("button", { name: view }));
}

describe("editing safety", () => {
  it("hydrates wizard answers from saved effective settings and falls back only for missing values", async () => {
    const fetch = editingFixture();
    await editingApp("Guided setup");
    expect(screen.getByLabelText(/Target file/)).toHaveValue("development-saved.txt");
    fireEvent.click(screen.getByRole("button", { name: "Continue to settings →" }));
    expect(screen.getByLabelText(/Message/)).toHaveValue("Saved message");
    expect(screen.getByLabelText(/^Enabled/)).toHaveValue("false");
    expect(screen.getByLabelText(/^Count/)).toHaveValue(0);
    expect(screen.getByLabelText(/^Items/)).toHaveValue("[]");
    expect(screen.getByLabelText(/^Nullable/)).toHaveValue("");
    expect(screen.getByLabelText(/^Missing/)).toHaveValue("fallback");
    fireEvent.click(screen.getByRole("button", { name: "Save answers →" }));
    await waitFor(() => expect(fetch.mock.calls.some(([url, init]) => url.endsWith("/wizard") && init?.method === "POST")).toBe(true));
    const [, request] = fetch.mock.calls.find(([url, init]) => url.endsWith("/wizard") && init?.method === "POST")!;
    expect(JSON.parse(String(request?.body)).values).toMatchObject({ enabled: false, count: 0, items: [], nil: null, missing: "fallback" });
  });

  it("refreshes saved wizard answers after an environment change", async () => {
    editingFixture();
    await editingApp("Guided setup");
    fireEvent.change(screen.getByLabelText("Active environment"), { target: { value: "staging" } });
    await waitFor(() => expect(screen.getByLabelText(/Target file/)).toHaveValue("staging-saved.txt"));
  });

  it("keeps reference-backed wizard values out of editable fields and blocks destructive wizard saving", async () => {
    editingFixture(true);
    await editingApp("Guided setup");
    expect(screen.queryByLabelText(/Target file/)).not.toBeInTheDocument();
    expect(screen.getByText(/reference-backed settings/i)).toBeVisible();
    fireEvent.click(screen.getByRole("button", { name: "Continue to settings →" }));
    expect(screen.getByRole("button", { name: "Save answers →" })).toBeDisabled();
  });

  it("preserves an unsaved project definition across page navigation", async () => {
    editingFixture();
    await editingApp();
    fireEvent.change(screen.getByLabelText("Portable project definition JSON"), { target: { value: '{"name":"Unsaved","formatVersion":1}' } });
    const nav = within(screen.getByRole("navigation", { name: "Main navigation" }));
    fireEvent.click(nav.getByRole("button", { name: "Configuration" }));
    fireEvent.click(nav.getByRole("button", { name: "Workspace" }));
    expect(screen.getByLabelText("Portable project definition JSON")).toHaveValue('{"name":"Unsaved","formatVersion":1}');
  });

  it("protects definition drafts on unload and project change, then clears dirty after save", async () => {
    editingFixture();
    vi.spyOn(window, "confirm").mockReturnValue(false);
    await editingApp();
    fireEvent.change(screen.getByLabelText("Portable project definition JSON"), { target: { value: '{"name":"Unsaved","formatVersion":1}' } });
    const unload = new Event("beforeunload", { cancelable: true });
    window.dispatchEvent(unload);
    expect(unload.defaultPrevented).toBe(true);
    fireEvent.click(screen.getByRole("button", { name: /Project q/ }));
    expect(window.confirm).toHaveBeenCalled();
    expect(screen.getByText("/isolated/p", { selector: "code" })).toBeVisible();
    fireEvent.click(screen.getByRole("button", { name: "Save definition" }));
    await screen.findByText(/Portable project definition saved\./);
    await waitFor(() => expect(screen.queryByText(/Unsaved project definition changes/)).not.toBeInTheDocument());
    expect(screen.queryByText(/Unsaved changes in/)).not.toBeInTheDocument();
    const cleanUnload = new Event("beforeunload", { cancelable: true });
    window.dispatchEvent(cleanUnload);
    expect(cleanUnload.defaultPrevented).toBe(false);
  });

  it("blocks saved-state execution while a parameter has unapplied JSON and requires explicit discard on navigation", async () => {
    editingFixture();
    vi.spyOn(window, "confirm").mockReturnValue(false);
    await editingApp("Plot editor");
    fireEvent.click(screen.getByRole("button", { name: /01\s*compose\s*text.join/ }));
    fireEvent.change(screen.getByLabelText("Items JSON value"), { target: { value: "[invalid" } });
    expect(screen.getByRole("button", { name: "Preflight plot" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "▶ Run plot" })).toBeDisabled();
    fireEvent.click(within(screen.getByRole("navigation", { name: "Main navigation" })).getByRole("button", { name: "Configuration" }));
    expect(window.confirm).toHaveBeenCalled();
    expect(screen.getByLabelText("Items JSON value")).toHaveValue("[invalid");
    vi.mocked(window.confirm).mockReturnValue(true);
    fireEvent.click(screen.getByRole("button", { name: /02\s*other\s*text.join/ }));
    expect(screen.getByRole("button", { name: "Preflight plot" })).toBeEnabled();
  });

  it("blocks layer saving for invalid parameter JSON and re-enables it after correction", async () => {
    editingFixture();
    await editingApp("Plot editor");
    fireEvent.click(screen.getByRole("button", { name: /01\s*compose\s*text.join/ }));
    const items = screen.getByLabelText("Items JSON value");
    fireEvent.change(items, { target: { value: '["changed"]' } });
    fireEvent.blur(items);
    expect(screen.getByRole("button", { name: "Save layer" })).toBeEnabled();
    fireEvent.change(items, { target: { value: "[invalid" } });
    fireEvent.blur(items);
    expect(screen.getByRole("button", { name: "Save layer" })).toBeDisabled();
    fireEvent.change(items, { target: { value: '["changed"]' } });
    fireEvent.blur(items);
    expect(screen.getByRole("button", { name: "Save layer" })).toBeEnabled();
  });

  it("blocks a cleared integer instead of silently running with its previous value", async () => {
    editingFixture();
    await editingApp("Plot editor");
    fireEvent.click(screen.getByRole("button", { name: /01\s*compose\s*text.join/ }));
    fireEvent.change(screen.getByLabelText("Count"), { target: { value: "" } });
    expect(screen.getByRole("button", { name: "▶ Run plot" })).toBeDisabled();
    fireEvent.change(screen.getByLabelText("Count value source"), { target: { value: "inherit" } });
    expect(screen.queryByText(/Unapplied parameter edits/)).not.toBeInTheDocument();
  });

  it("does not discard invalid parameter A when editing parameter B reclones the invocation", async () => {
    editingFixture();
    await editingApp("Plot editor");
    fireEvent.click(screen.getByRole("button", { name: /01\s*compose\s*text.join/ }));
    fireEvent.change(screen.getByLabelText("Items JSON value"), { target: { value: "[invalid" } });
    fireEvent.change(screen.getByLabelText("Count"), { target: { value: "3" } });
    expect(screen.getByLabelText("Items JSON value")).toHaveValue("[invalid");
    expect(screen.getByRole("button", { name: "Save layer" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "▶ Run plot" })).toBeDisabled();
  });

  it("protects a definition draft from environment changes and sign-out", async () => {
    const fetch = editingFixture();
    vi.spyOn(window, "confirm").mockReturnValue(false);
    await editingApp();
    fireEvent.change(screen.getByLabelText("Portable project definition JSON"), { target: { value: '{"name":"Unsaved","formatVersion":1}' } });
    fireEvent.change(screen.getByLabelText("Active environment"), { target: { value: "staging" } });
    expect(screen.getByLabelText("Active environment")).toHaveValue("development");
    fireEvent.click(screen.getByRole("button", { name: "Sign out · operator" }));
    expect(fetch.mock.calls.some(([url, request]) => url === "/api/session" && request?.method === "DELETE")).toBe(false);
    expect(screen.getByLabelText("Portable project definition JSON")).toHaveValue('{"name":"Unsaved","formatVersion":1}');
  });

  it("refreshes wizard values after saving configuration without changing project or environment", async () => {
    editingFixture();
    await editingApp("Configuration");
    const source = screen.getByLabelText("Editable layer JSON");
    const updated = JSON.parse((source as HTMLTextAreaElement).value);
    updated.Values.Message = "Updated saved message";
    fireEvent.change(source, { target: { value: JSON.stringify(updated) } });
    fireEvent.click(screen.getByRole("button", { name: "Save layer" }));
    await screen.findByText(/Saved only Project/);
    fireEvent.click(within(screen.getByRole("navigation", { name: "Main navigation" })).getByRole("button", { name: "Guided setup" }));
    fireEvent.click(screen.getByRole("button", { name: "Continue to settings →" }));
    expect(screen.getByLabelText(/Message/)).toHaveValue("Updated saved message");
  });
});
