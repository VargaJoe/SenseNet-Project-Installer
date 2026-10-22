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
