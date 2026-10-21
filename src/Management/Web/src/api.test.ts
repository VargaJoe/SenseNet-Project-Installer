import { afterEach, describe, expect, it, vi } from "vitest";
import { api, ApiError, post, takeBootstrapToken } from "./api";

afterEach(() => vi.unstubAllGlobals());
describe("same-origin authenticated requests", () => {
  it("exchanges mutating calls with CSRF marker and HttpOnly cookie credentials", async () => {
    const fetch = vi.fn().mockResolvedValue(new Response('{"ok":true}'));
    vi.stubGlobal("fetch", fetch);
    await post("/session", { token: "private-test-token" });
    const [url, options] = fetch.mock.calls[0];
    expect(url).toBe("/api/session");
    expect(options.credentials).toBe("include");
    expect(options.headers.get("X-Plot-Request")).toBe("1");
    expect(options.headers.get("Content-Type")).toBe("application/json");
  });
  it("retains a conflict response for user-visible optimistic concurrency handling", async () => {
    vi.stubGlobal(
      "fetch",
      vi
        .fn()
        .mockResolvedValue(
          new Response('{"error":"The layer changed.","code":"conflict"}', {
            status: 409,
          }),
        ),
    );
    await expect(api("/projects/test/layers/project")).rejects.toMatchObject({
      message: "The layer changed.",
      status: 409,
      code: "conflict",
    });
  });
  it("erases fragment credentials before any asynchronous API request and uses no browser storage", () => {
    history.replaceState(
      null,
      "",
      "/?project=project-id#token=one-time-bootstrap",
    );
    expect(takeBootstrapToken()).toBe("one-time-bootstrap");
    expect(location.hash).toBe("");
    expect(location.search).toBe("?project=project-id");
    expect(localStorage.length).toBe(0);
    expect(sessionStorage.length).toBe(0);
  });
});
