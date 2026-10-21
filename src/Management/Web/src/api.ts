export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public code?: string,
  ) {
    super(message);
  }
}
export async function api<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  if (options.body) headers.set("Content-Type", "application/json");
  if (options.method && options.method !== "GET")
    headers.set("X-Plot-Request", "1");
  const response = await fetch(`/api${path}`, {
    ...options,
    credentials: "include",
    headers,
  });
  const text = await response.text();
  let data: unknown;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    throw new ApiError(
      `The service returned an unreadable response (${response.status}).`,
      response.status,
    );
  }
  if (!response.ok) {
    const error = data as { error?: string; code?: string } | null;
    throw new ApiError(
      error?.error || `Request failed (${response.status}).`,
      response.status,
      error?.code,
    );
  }
  return data as T;
}
export const post = <T>(path: string, body: unknown) =>
  api<T>(path, { method: "POST", body: JSON.stringify(body) });
export const put = <T>(path: string, body: unknown) =>
  api<T>(path, { method: "PUT", body: JSON.stringify(body) });
export const segment = encodeURIComponent;
export function takeBootstrapToken(): string | null {
  const token = new URLSearchParams(location.hash.slice(1)).get("token");
  if (token !== null)
    history.replaceState(null, "", location.pathname + location.search);
  return token;
}
