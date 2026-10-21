import { cleanup, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import App from "./App";

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  history.replaceState(null, "", "/");
});

describe("managed run session lifecycle", () => {
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
