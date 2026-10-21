import { useCallback, useEffect, useRef, useState } from "react";
import { api, ApiError, post, put, segment, takeBootstrapToken } from "./api";
import {
  isLosslessNumber,
  numberInput,
  parseJson,
  stringifyJson,
} from "./json";
import {
  Badge,
  Empty,
  JsonEditor,
  JsonView,
  Notice,
  ParameterField,
} from "./components";
import {
  active,
  clone,
  duration,
  flatten,
  invocationId,
  member,
  setMember,
  moveStep,
  object,
  parseObject,
  plotNames,
  ownsPlotSteps,
  plotSource,
  plotSteps,
  pretty,
  removeOverride,
  setPlotSteps,
  type CatalogStep,
  type EngineConfiguration,
  type Invocation,
  type Json,
  type JsonObject,
  type Layer,
  type LayerInfo,
  type Plan,
  type Project,
  type Run,
  type RunEvent,
  type Runner,
  type Wizard,
} from "./model";

type Session = { authenticated: boolean; user: string; mode: string };
type View = "workspace" | "plot" | "layers" | "runs" | "wizard" | "secrets";
const views: { id: View; label: string; glyph: string }[] = [
  { id: "workspace", label: "Workspace", glyph: "◈" },
  { id: "plot", label: "Plot editor", glyph: "☷" },
  { id: "layers", label: "Configuration", glyph: "▱" },
  { id: "runs", label: "Run history", glyph: "◷" },
  { id: "wizard", label: "Guided setup", glyph: "✧" },
  { id: "secrets", label: "Runner secrets", glyph: "⚿" },
];
const errText = (error: unknown) =>
  error instanceof Error ? error.message : String(error);
const stamp = (value?: string) =>
  value ? new Date(value).toLocaleString() : "—";
const readQuery = (key: string) =>
  new URLSearchParams(location.search).get(key) || "";
const getWizard = (pid: string) =>
  api<Wizard>(`${pid}/wizard`).catch((error) => {
    if (error instanceof ApiError && error.status === 404) return undefined;
    throw error;
  });
function updateQuery(key: string, value: string) {
  const url = new URL(location.href);
  if (value || key === "environment") url.searchParams.set(key, value);
  else url.searchParams.delete(key);
  history.replaceState(null, "", url);
}

export default function App() {
  const [session, setSession] = useState<Session>();
  const [booting, setBooting] = useState(true);
  const [token, setToken] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [pending, setPending] = useState(0);
  const [runner, setRunner] = useState<Runner>();
  const [projects, setProjects] = useState<Project[]>([]);
  const [project, setProject] = useState<Project>();
  const [catalog, setCatalog] = useState<CatalogStep[]>([]);
  const [view, setView] = useState<View>("workspace");
  const [environment, setEnvironment] = useState("");
  const [layers, setLayers] = useState<LayerInfo[]>([]);
  const [layerId, setLayerId] = useState("project");
  const [layer, setLayer] = useState<Layer>();
  const [draft, setDraft] = useState("{}");
  const [configuration, setConfiguration] = useState<EngineConfiguration>();
  const [plot, setPlot] = useState("");
  const [selectedInvocation, setSelectedInvocation] = useState("");
  const [overrides, setOverrides] = useState("{}");
  const [plan, setPlan] = useState<Plan>();
  const [runs, setRuns] = useState<Run[]>([]);
  const [run, setRun] = useState<Run>();
  const [events, setEvents] = useState<RunEvent[]>([]);
  const [connection, setConnection] = useState("");
  const [wizard, setWizard] = useState<Wizard>();
  const [wizardValues, setWizardValues] = useState<JsonObject>({});
  const [wizardStage, setWizardStage] = useState(0);
  const [wizardPlan, setWizardPlan] = useState<Plan>();
  const [wizardRunId, setWizardRunId] = useState("");
  const generation = useRef(0);
  const dirty = !!layer && draft !== pretty(layer.data);
  const busy = pending > 0;
  const locked = runs.some(active);
  const pid = project ? `/projects/${segment(project.id)}` : "";
  const currentLocation = useRef({ pid, environment, layerId });
  currentLocation.current = { pid, environment, layerId };
  const protectedAction = async (fn: () => Promise<void>) => {
    setError("");
    setSuccess("");
    setPending((x) => x + 1);
    try {
      await fn();
    } catch (e) {
      if (e instanceof ApiError && e.status === 401)
        setSession({ authenticated: false, user: "", mode: "" });
      setError(errText(e));
    } finally {
      setPending((x) => x - 1);
    }
  };

  useEffect(() => {
    void (async () => {
      try {
        const initialToken = takeBootstrapToken();
        setSession(
          initialToken
            ? await post<Session>("/session", { token: initialToken })
            : await api<Session>("/session"),
        );
      } catch (e) {
        setError(errText(e));
      } finally {
        setBooting(false);
      }
    })();
  }, []);

  const refreshProjects = useCallback(async () => {
    const result = await api<{ projects: Project[] }>("/projects");
    setProjects(result.projects);
    return result.projects;
  }, []);
  useEffect(() => {
    if (!session?.authenticated) return;
    void protectedAction(async () => {
      const [host, steps, list] = await Promise.all([
        api<Runner>("/runner"),
        api<{ engine: { Steps: CatalogStep[] } }>("/catalog"),
        refreshProjects(),
      ]);
      setRunner(host);
      setCatalog(steps.engine.Steps);
      const selected = list.find((p) => p.id === readQuery("project"));
      if (selected) {
        setProject(selected);
        const query = new URLSearchParams(location.search);
        const requested = query.get("environment") || "";
        setEnvironment(
          query.has("environment") &&
            (!requested || selected.environments.includes(requested))
            ? requested
            : selected.environments[0] || "",
        );
      }
    });
  }, [session?.authenticated, refreshProjects]);

  const loadConfiguration = useCallback(async () => {
    if (!pid) return;
    const [result, available] = await Promise.all([
      api<{ engine: EngineConfiguration }>(
        `${pid}/configuration?environment=${segment(environment)}`,
      ),
      api<{ layers: LayerInfo[] }>(
        `${pid}/layers?environment=${segment(environment)}`,
      ),
    ]);
    const documents = await Promise.all(
      available.layers.map((item) =>
        api<Layer>(`${pid}/layers/${segment(item.id)}`),
      ),
    );
    if (
      currentLocation.current.pid !== pid ||
      currentLocation.current.environment !== environment
    )
      return;
    const nativeLayers = Array.isArray(result.engine.Layers)
      ? result.engine.Layers
      : [];
    const rawLayers = documents.map((document, index) => {
      const source = nativeLayers[index];
      if (!object(source) || typeof source.Path !== "string")
        throw new Error(
          "The engine did not identify this configuration source file. Reload before editing inherited steps.",
        );
      return { ...document, file: source.Path };
    });
    setConfiguration({ ...result.engine, RawLayers: rawLayers });
    setPlan(undefined);
    setWizardPlan(undefined);
    setPlot((previous) =>
      plotNames(result.engine.Configuration).includes(previous)
        ? previous
        : plotNames(result.engine.Configuration)[0] || "",
    );
    return result.engine;
  }, [pid, environment]);

  const loadLayer = useCallback(async () => {
    if (!pid) return;
    const result = await api<Layer>(`${pid}/layers/${segment(layerId)}`);
    if (
      currentLocation.current.pid !== pid ||
      currentLocation.current.layerId !== layerId
    )
      return;
    setLayer(result);
    setDraft(pretty(result.data));
    return result;
  }, [pid, layerId]);

  const refreshRuns = useCallback(async () => {
    if (!pid) return [];
    const result = await api<{ runs: Run[] }>(`${pid}/runs`);
    if (currentLocation.current.pid === pid) setRuns(result.runs);
    return result.runs;
  }, [pid]);
  useEffect(() => {
    if (!project) return;
    const expectedGeneration = ++generation.current;
    setRun(undefined);
    setEvents([]);
    setConfiguration(undefined);
    setOverrides("{}");
    setSelectedInvocation("");
    setWizardStage(0);
    setWizardRunId("");
    setRuns([]);
    updateQuery("project", project.id);
    updateQuery("environment", environment);
    void protectedAction(async () => {
      const [available, , history, descriptor] = await Promise.all([
        api<{ layers: LayerInfo[] }>(
          `${pid}/layers?environment=${segment(environment)}`,
        ),
        loadConfiguration(),
        refreshRuns(),
        getWizard(pid),
      ]);
      if (expectedGeneration !== generation.current) return;
      setLayers(available.layers);
      setWizard(descriptor);
      setWizardValues(
        descriptor
          ? Object.fromEntries(
              descriptor.groups.flatMap((group) =>
                group.fields
                  .filter((field) => Object.hasOwn(field, "default"))
                  .map((field) => [field.key, field.default!]),
              ),
            )
          : {},
      );
      const previousRun =
        history.find((r) => r.id === readQuery("run")) || history.find(active);
      if (previousRun) setRun(previousRun);
    });
  }, [project?.id, environment, loadConfiguration, refreshRuns]);

  useEffect(() => {
    if (pid)
      void protectedAction(async () => {
        await loadLayer();
      });
  }, [pid, loadLayer]);

  useEffect(() => {
    const beforeUnload = (event: BeforeUnloadEvent) => {
      if (dirty) {
        event.preventDefault();
        event.returnValue = "";
      }
    };
    addEventListener("beforeunload", beforeUnload);
    return () => removeEventListener("beforeunload", beforeUnload);
  }, [dirty]);

  useEffect(() => {
    if (!run || !pid || !session?.authenticated) return;
    const runId = run.id,
      expectedGeneration = generation.current;
    updateQuery("run", runId);
    setEvents([]);
    setConnection("Connecting…");
    let cursor = 0,
      disposed = false,
      timer: ReturnType<typeof setTimeout>;
    const poll = async () => {
      try {
        const [record, replay] = await Promise.all([
          api<Run>(`${pid}/runs/${segment(runId)}`),
          api<{ events: RunEvent[]; cursor: number; status: string }>(
            `${pid}/runs/${segment(runId)}/events?after=${cursor}`,
          ),
        ]);
        if (disposed || expectedGeneration !== generation.current) return;
        const incoming = replay.events.filter((e) => e.cursor > cursor);
        setRun(record);
        setEvents((previous) => [...previous, ...incoming]);
        cursor = replay.cursor;
        setRuns((previous) =>
          [record, ...previous.filter((r) => r.id !== record.id)].sort((a, b) =>
            b.createdAt.localeCompare(a.createdAt),
          ),
        );
        setConnection(
          active(record)
            ? "Live · cursor replay connected"
            : "Complete · durable events loaded",
        );
        if (active(record)) timer = setTimeout(poll, 1000);
      } catch (e) {
        if (disposed) return;
        if (e instanceof ApiError && e.status === 401) {
          setError(
            "Your session expired. Sign in again to reconnect to the saved run.",
          );
          setSession({ authenticated: false, user: "", mode: "" });
          return;
        }
        setConnection(
          `Connection interrupted. Retrying from cursor ${cursor}: ${errText(e)}`,
        );
        timer = setTimeout(poll, 3000);
      }
    };
    void poll();
    return () => {
      disposed = true;
      clearTimeout(timer);
    };
  }, [run?.id, pid, session?.authenticated]);

  const chooseProject = (p: Project) => {
    if (
      dirty &&
      !window.confirm("Discard unsaved changes in the selected layer?")
    )
      return;
    setLayer(undefined);
    setDraft("{}");
    setProject(p);
    setEnvironment(p.environments[0] || "");
    setLayerId("project");
    setView("workspace");
    updateQuery("run", "");
  };
  const changeEnvironment = (value: string) => {
    if (
      dirty &&
      !window.confirm("Discard unsaved layer changes and switch environment?")
    )
      return;
    setEnvironment(value);
    if (layerId.startsWith("environment:")) {
      setLayer(undefined);
      setDraft("{}");
      setLayerId(value ? `environment:${value}` : "project");
    }
  };
  const changeLayer = (value: string) => {
    if (
      dirty &&
      !window.confirm("Discard unsaved changes and select a different layer?")
    )
      return;
    setLayer(undefined);
    setDraft("{}");
    setLayerId(value);
  };
  const save = async () => {
    if (!layer) throw new Error("Select a configuration layer.");
    const data = parseObject(draft);
    const result = await put<Layer>(`${pid}/layers/${segment(layerId)}`, {
      etag: layer.etag,
      data,
    });
    setLayer(result);
    setDraft(pretty(result.data));
    await loadConfiguration();
    setSuccess(
      `Saved only ${layer.label || layerId}. Effective configuration refreshed by the engine.`,
    );
  };
  const requestBody = (name = plot, invocation?: string) => ({
    plot: name,
    environment,
    overrides: parseObject(overrides),
    ...(invocation ? { invocationId: invocation } : {}),
  });
  const check = async (invocation?: string) => {
    if (dirty)
      throw new Error("Save the selected layer before preflight or execution.");
    const result = await post<{ engine: Plan }>(
      `${pid}/plan`,
      requestBody(plot, invocation),
    );
    setPlan(result.engine);
    setSuccess(
      `Static preflight passed${invocation ? ` for ${invocation}` : ""}. No package commands or connection tests were invoked.`,
    );
  };
  const start = async (whatIf: boolean, invocation?: string, name = plot) => {
    if (dirty) throw new Error("Save the selected layer before execution.");
    const body = requestBody(name, invocation);
    await post(`${pid}/plan`, body);
    const record = await post<Run>(`${pid}/runs`, { ...body, whatIf });
    setRun(record);
    await refreshRuns();
    setView("runs");
    return record;
  };
  const effective = configuration?.Configuration ?? {};
  let draftObject: JsonObject | undefined,
    draftError = "";
  try {
    draftObject = parseObject(draft);
  } catch (e) {
    draftError = errText(e);
  }
  const exactPlotSource =
    draftObject && ownsPlotSteps(draftObject, plot)
      ? draftObject
      : configuration
        ? plotSource(configuration, plot)
        : undefined;
  let steps: Invocation[] = [];
  try {
    steps = plotSteps(exactPlotSource ?? {}, plot);
  } catch (e) {
    draftError ||= errText(e);
  }
  const selected = steps.find((step) => step.Id === selectedInvocation);
  const selectedSchema = catalog.find((step) => step.Id === selected?.Step);
  const editSteps = (next: Invocation[]) => {
    if (!draftObject) return;
    if (!exactPlotSource && plotNames(effective).includes(plot)) {
      setError(
        "The engine source array is not loaded. Reload configuration before changing inherited steps.",
      );
      return;
    }
    setDraft(
      pretty(
        setPlotSteps(draftObject, exactPlotSource ?? effective, plot, next),
      ),
    );
    setPlan(undefined);
  };
  const updateInvocation = (next: Invocation) =>
    editSteps(
      steps.map((step) => (step.Id === selectedInvocation ? next : step)),
    );
  const changePlot = (name: string) => {
    setPlot(name);
    setSelectedInvocation("");
    setPlan(undefined);
  };
  const availablePlots = [
    ...new Set([
      ...plotNames(effective),
      ...(draftObject ? plotNames(draftObject) : []),
    ]),
  ];

  if (booting)
    return (
      <div className="login-shell">
        <div className="brand-mark">P</div>
        <p>Connecting to Plot Manager…</p>
      </div>
    );
  if (!session?.authenticated)
    return (
      <div className="login-shell">
        <main className="login-card">
          <div className="brand-mark">P</div>
          <p className="eyebrow">PLOT MANAGER · PROTOCOL 1</p>
          <h1>
            Your operations,
            <br />
            one clear workspace.
          </h1>
          <p className="muted">
            Sign in to the service host. Plots execute as its configured runner
            identity.
          </p>
          {error && <Notice kind="error">{error}</Notice>}
          <form
            onSubmit={(e) => {
              e.preventDefault();
              void protectedAction(async () => {
                const next = await post<Session>("/session", { token });
                setToken("");
                setSession(next);
              });
            }}
          >
            <label className="field">
              Access token
              <input
                type="password"
                value={token}
                onChange={(e) => setToken(e.target.value)}
                autoComplete="off"
                required
              />
            </label>
            <button className="primary full" type="submit" disabled={busy}>
              Connect to workspace
            </button>
          </form>
          <p className="help">
            Access tokens are exchanged for an HttpOnly session cookie. They are
            never written to project files or browser storage.
          </p>
        </main>
      </div>
    );

  return (
    <div
      className="app-shell"
      data-testid={runner ? "management-ready" : undefined}
    >
      <aside className="sidebar">
        <a
          className="brand"
          href="#"
          onClick={(e) => {
            e.preventDefault();
            setView("workspace");
          }}
        >
          <span className="brand-mark">P</span>
          <span>
            Plot Manager<small>OPERATIONS WORKSPACE</small>
          </span>
        </a>
        <div className="sidebar-project">
          <span className="eyebrow">ACTIVE PROJECT</span>
          <strong>{project?.name || "Select a project"}</strong>
          <span>
            {project
              ? `${availablePlots.length} plots · ${environment}`
              : "Ready when you are"}
          </span>
        </div>
        <nav aria-label="Main navigation">
          {views.map((item) => (
            <button
              key={item.id}
              className={view === item.id ? "nav-item selected" : "nav-item"}
              onClick={() => setView(item.id)}
              disabled={
                !project && item.id !== "workspace" && item.id !== "secrets"
              }
            >
              <span aria-hidden="true">{item.glyph}</span>
              {item.label}
              {item.id === "runs" && locked && <span className="live-dot" />}
            </button>
          ))}
        </nav>
        <div className="runner-card">
          <span className="live-dot" />
          <strong>{runner?.displayName || "Service host"}</strong>
          <small>
            {runner?.os} · {runner?.mode}
          </small>
          <span>Sequential engine · v{runner?.protocolVersion || 1}</span>
        </div>
        <button
          className="sign-out"
          onClick={() =>
            void protectedAction(async () => {
              await api("/session", { method: "DELETE" });
              setSession({ authenticated: false, user: "", mode: "" });
              setProject(undefined);
              setToken("");
            })
          }
        >
          Sign out · {session.user}
        </button>
      </aside>
      <div className="main-shell">
        <header className="topbar">
          <div className="breadcrumbs">
            Workspace <span>/</span> {project?.name || "Projects"}{" "}
            <span>/</span>{" "}
            <strong>{views.find((v) => v.id === view)?.label}</strong>
          </div>
          <span className="host-label">
            <span className="live-dot" />{" "}
            {runner?.identity || "Loading runner identity"}
          </span>
        </header>
        <main className="main-content" aria-busy={busy}>
          <div className="page-heading">
            <div>
              <p className="eyebrow">
                {project
                  ? `${environment} / ${runner?.displayName || "service host"}`
                  : "YOUR AUTOMATION, ORGANIZED"}
              </p>
              <h1>{views.find((v) => v.id === view)?.label}</h1>
              <p className="muted">
                {view === "workspace"
                  ? "Build once. Inspect every layer. Run with confidence."
                  : view === "plot"
                    ? "A sequential plan with stable invocation IDs and engine-validated settings."
                    : view === "layers"
                      ? "Edit one explicit source layer. Let the engine explain the effective result."
                      : view === "runs"
                        ? "Durable execution records, live events, and structured results."
                        : view === "wizard"
                          ? "A guided path from a fresh project to a real, portable sample plot."
                          : "Store service-local values and reference them from configuration."}
              </p>
            </div>
            {project && (
              <label className="environment-control">
                Environment
                <select
                  aria-label="Active environment"
                  value={environment}
                  onChange={(e) => changeEnvironment(e.target.value)}
                >
                  <option value="">Project layers only</option>
                  {project.environments.map((env) => (
                    <option key={env}>{env}</option>
                  ))}
                </select>
              </label>
            )}
          </div>
          {error && (
            <Notice kind="error">
              {error}
              {error.includes("409") || error.toLowerCase().includes("changed")
                ? " Reload the selected layer, review the other changes, then apply your edits again."
                : ""}
              <button
                className="notice-close"
                aria-label="Dismiss error"
                onClick={() => setError("")}
              >
                ×
              </button>
            </Notice>
          )}
          {success && (
            <Notice kind="success">
              {success}
              <button
                className="notice-close"
                aria-label="Dismiss message"
                onClick={() => setSuccess("")}
              >
                ×
              </button>
            </Notice>
          )}
          {project && (
            <div className="context-bar">
              <div>
                <span className="context-label">PROJECT DIRECTORY</span>
                <code>{project.directory}</code>
              </div>
              <div>
                <span className="context-label">EXECUTION TARGET</span>
                <span>
                  {runner?.displayName} <small>as {runner?.identity}</small>
                </span>
              </div>
              <Badge>{locked ? "Running" : "Ready"}</Badge>
            </div>
          )}
          {project && dirty && (
            <Notice kind="warning">
              Unsaved changes in <strong>{layer?.label || layerId}</strong>.
              Preflight and run use saved files.
              <button
                className="small"
                disabled={busy || locked || !!draftError}
                onClick={() => void protectedAction(save)}
              >
                Save selected layer
              </button>
            </Notice>
          )}
          {locked && view !== "runs" && (
            <Notice>
              A run holds this project’s edit lock. Inspect progress in Run
              history; editing resumes after it completes.
            </Notice>
          )}

          {view === "workspace" && (
            <Workspace
              projects={projects}
              project={project}
              onSelect={chooseProject}
              effective={effective}
              catalogCount={catalog.length}
              onCreate={(name, directory, template) =>
                protectedAction(async () => {
                  const created = await post<Project>("/projects", {
                    name,
                    ...(directory ? { directory } : {}),
                    ...(template ? { template: "generic" } : {}),
                  });
                  await refreshProjects();
                  chooseProject(created);
                  if (template) setView("wizard");
                })
              }
              onOpen={(directory) =>
                protectedAction(async () => {
                  const opened = await post<Project>("/projects/open", {
                    directory,
                  });
                  await refreshProjects();
                  chooseProject(opened);
                })
              }
              onEnvironment={(name) =>
                protectedAction(async () => {
                  await post(`${pid}/environments`, { name });
                  const updated = await api<Project>(pid);
                  setProject(updated);
                  setEnvironment(name);
                  setLayerId(`environment:${name}`);
                })
              }
              onBrowse={() => setView("layers")}
              onNavigate={setView}
              busy={busy}
            />
          )}

          {project && view === "workspace" && (
            <DefinitionEditor
              pid={pid}
              locked={locked || dirty}
              onError={setError}
              onSaved={() =>
                protectedAction(async () => {
                  const updated = await api<Project>(pid);
                  setProject(updated);
                  if (
                    environment &&
                    !updated.environments.includes(environment)
                  )
                    setEnvironment(updated.environments[0] || "");
                  await refreshProjects();
                  const available = await api<{ layers: LayerInfo[] }>(
                    `${pid}/layers?environment=${segment(environment && updated.environments.includes(environment) ? environment : "")}`,
                  );
                  setLayers(available.layers);
                  setLayerId("project");
                  await Promise.all([
                    loadConfiguration(),
                    layerId === "project" ? loadLayer() : Promise.resolve(),
                  ]);
                  setWizard(await getWizard(pid));
                  setSuccess(
                    "Portable project definition saved. Configuration paths and wizard binding are validated by the service.",
                  );
                })
              }
            />
          )}
          {project && (view === "plot" || view === "layers") && (
            <div className="editor-toolbar">
              <label>
                Editing source layer
                <select
                  aria-label="Selected configuration layer"
                  value={layerId}
                  onChange={(e) => changeLayer(e.target.value)}
                >
                  {layers.map((item) => (
                    <option key={item.id} value={item.id}>
                      {item.label || item.id}
                    </option>
                  ))}
                </select>
              </label>
              <span className="source-path">
                {layer?.path}
                <small>version {layer?.etag?.slice(0, 12)}</small>
              </span>
              <button
                className="small"
                onClick={() => {
                  if (
                    !dirty ||
                    window.confirm(
                      "Discard unsaved changes and load the latest file?",
                    )
                  )
                    void protectedAction(async () => {
                      await Promise.all([loadLayer(), loadConfiguration()]);
                    });
                }}
              >
                Reload
              </button>
              <button
                className="primary small"
                disabled={!dirty || busy || locked || !!draftError}
                onClick={() => void protectedAction(save)}
              >
                Save layer
              </button>
            </div>
          )}

          {project && view === "plot" && (
            <>
              <div className="plot-toolbar">
                <label>
                  Plot
                  <select
                    aria-label="Selected plot"
                    value={plot}
                    onChange={(e) => changePlot(e.target.value)}
                  >
                    {availablePlots.map((name) => (
                      <option key={name}>{name}</option>
                    ))}
                  </select>
                </label>
                <button
                  className="small"
                  onClick={() => {
                    const name = window.prompt("New plot name");
                    if (name?.trim() && draftObject) {
                      setDraft(
                        pretty(
                          setPlotSteps(draftObject, effective, name.trim(), []),
                        ),
                      );
                      changePlot(name.trim());
                    }
                  }}
                  disabled={locked || !layer || busy}
                >
                  + New plot
                </button>
                <div className="toolbar-spacer" />
                <button
                  className="small"
                  disabled={!plot || busy || dirty || locked}
                  onClick={() => void protectedAction(() => check())}
                >
                  Preflight plot
                </button>
                <button
                  className="small"
                  disabled={!plot || busy || dirty || locked}
                  onClick={() =>
                    void protectedAction(async () => {
                      await start(true);
                    })
                  }
                >
                  WhatIf preview
                </button>
                <button
                  className="primary small"
                  disabled={!plot || busy || dirty || locked}
                  onClick={() =>
                    void protectedAction(async () => {
                      await start(false);
                    })
                  }
                >
                  ▶ Run plot
                </button>
              </div>
              <div className="notice subtle">
                Static preflight and WhatIf never invoke package commands or
                active connection tests. Every run preflights the full selected
                scope before executing.
              </div>
              {draftError && (
                <Notice kind="error">
                  {draftError} Open Configuration to correct the layer JSON.
                </Notice>
              )}
              <div className="plot-layout">
                <section className="panel step-list">
                  <div className="panel-heading">
                    <h2>
                      Sequential steps{" "}
                      <span className="count">{steps.length}</span>
                    </h2>
                    <Badge>In order</Badge>
                  </div>
                  {!steps.length && (
                    <Empty title="Start with a step">
                      Add an installed step below to compose this plot.
                    </Empty>
                  )}
                  <ol className="invocations">
                    {steps.map((step, index) => (
                      <li
                        key={step.Id}
                        className={
                          selectedInvocation === step.Id
                            ? "invocation selected"
                            : "invocation"
                        }
                      >
                        <button
                          className="invocation-main"
                          onClick={() => setSelectedInvocation(step.Id)}
                        >
                          <span className="step-index">
                            {String(index + 1).padStart(2, "0")}
                          </span>
                          <span>
                            <strong>{step.Id}</strong>
                            <small>{step.Step}</small>
                          </span>
                        </button>
                        <div className="invocation-actions">
                          <button
                            title={`Move ${step.Id} earlier`}
                            aria-label={`Move ${step.Id} earlier`}
                            disabled={!index || locked || !layer || busy}
                            onClick={() =>
                              editSteps(moveStep(steps, index, -1))
                            }
                          >
                            ↑
                          </button>
                          <button
                            title={`Move ${step.Id} later`}
                            aria-label={`Move ${step.Id} later`}
                            disabled={
                              index === steps.length - 1 ||
                              locked ||
                              !layer ||
                              busy
                            }
                            onClick={() => editSteps(moveStep(steps, index, 1))}
                          >
                            ↓
                          </button>
                          <button
                            title={`Copy ${step.Id}`}
                            aria-label={`Copy ${step.Id}`}
                            disabled={locked || !layer || busy}
                            onClick={() => {
                              const copy = clone(step);
                              copy.Id = invocationId(
                                step.Step,
                                steps.map((s) => s.Id),
                              );
                              const next = clone(steps);
                              next.splice(index + 1, 0, copy);
                              editSteps(next);
                              setSelectedInvocation(copy.Id);
                            }}
                          >
                            ⧉
                          </button>
                          <button
                            title={`Remove ${step.Id}`}
                            aria-label={`Remove ${step.Id}`}
                            disabled={locked || !layer || busy}
                            onClick={() => {
                              editSteps(steps.filter((s) => s.Id !== step.Id));
                              if (selectedInvocation === step.Id)
                                setSelectedInvocation("");
                            }}
                          >
                            ×
                          </button>
                        </div>
                      </li>
                    ))}
                  </ol>
                  <StepCatalog
                    catalog={catalog}
                    disabled={locked || busy || !layer || !draftObject || !plot}
                    onAdd={(step) => {
                      const id = invocationId(
                        step.Id,
                        steps.map((s) => s.Id),
                      );
                      editSteps([
                        ...steps,
                        { Id: id, Step: step.Id, With: {} },
                      ]);
                      setSelectedInvocation(id);
                    }}
                  />
                </section>
                <section className="panel parameters-panel">
                  {selected ? (
                    <>
                      <div className="panel-heading">
                        <div>
                          <p className="eyebrow">INVOCATION SETTINGS</p>
                          <h2>{selected.Id}</h2>
                        </div>
                        <Badge>{selected.Step}</Badge>
                      </div>
                      <div className="parameter-body">
                        <label className="field">
                          Stable invocation ID
                          <input
                            value={selected.Id}
                            pattern="[A-Za-z][A-Za-z0-9_-]*"
                            disabled={locked || busy || !layer}
                            onChange={(e) => {
                              const nextId = e.target.value;
                              updateInvocation({ ...selected, Id: nextId });
                              setSelectedInvocation(nextId);
                            }}
                          />
                        </label>
                        <label className="field">
                          Configuration section (optional)
                          <input
                            value={
                              typeof selected.Section === "string"
                                ? selected.Section
                                : ""
                            }
                            disabled={locked || busy || !layer}
                            onChange={(e) => {
                              const next = clone(selected);
                              if (e.target.value) next.Section = e.target.value;
                              else delete next.Section;
                              updateInvocation(next);
                            }}
                          />
                        </label>
                        <p className="help">
                          IDs remain unchanged when reordered. Renaming an ID
                          requires updating references that point to it.
                        </p>
                        {selectedSchema ? (
                          Object.entries(selectedSchema.Parameters).map(
                            ([name, schema]) => (
                              <ParameterField
                                key={`${selected.Id}-${name}`}
                                name={name}
                                schema={schema}
                                value={member(selected.With, name)}
                                disabled={locked || busy || !layer}
                                references={[
                                  ...flatten(effective)
                                    .filter(
                                      ([path]) =>
                                        !path
                                          .toLowerCase()
                                          .startsWith("/plots"),
                                    )
                                    .map(
                                      ([path]) =>
                                        `settings.${path.slice(1).replace(/\//g, ".")}`,
                                    ),
                                  ...steps
                                    .slice(0, steps.indexOf(selected))
                                    .flatMap((step) => {
                                      const outputs = catalog.find(
                                        (c) => c.Id === step.Step,
                                      )?.Outputs;
                                      return outputs && object(outputs)
                                        ? Object.keys(outputs).map(
                                            (output) =>
                                              `steps.${step.Id}.Output.${output}`,
                                          )
                                        : [`steps.${step.Id}.Output`];
                                    }),
                                ]}
                                onChange={(value) => {
                                  const next = clone(selected);
                                  setMember(next.With, name, value);
                                  updateInvocation(next);
                                }}
                              />
                            ),
                          )
                        ) : (
                          <Notice kind="error">
                            This step is not in the installed catalog. Use JSON
                            to inspect unknown fields; the engine rejects
                            unavailable steps.
                          </Notice>
                        )}
                        {selectedSchema?.Outputs && (
                          <details>
                            <summary>Declared output metadata</summary>
                            <JsonView value={selectedSchema.Outputs} />
                          </details>
                        )}
                        <div className="button-row">
                          <button
                            className="small"
                            disabled={busy || dirty || locked}
                            onClick={() =>
                              void protectedAction(() => check(selected.Id))
                            }
                          >
                            Preflight invocation
                          </button>
                          <button
                            className="small"
                            disabled={busy || dirty || locked}
                            onClick={() =>
                              void protectedAction(async () => {
                                await start(true, selected.Id);
                              })
                            }
                          >
                            WhatIf invocation
                          </button>
                          <button
                            className="primary small"
                            disabled={busy || dirty || locked}
                            onClick={() =>
                              void protectedAction(async () => {
                                await start(false, selected.Id);
                              })
                            }
                          >
                            Run invocation
                          </button>
                        </div>
                        <p className="help">
                          A single invocation cannot consume previous output
                          from another run. Its dependencies must stand alone.
                        </p>
                      </div>
                    </>
                  ) : (
                    <Empty title="Select an invocation">
                      Inspect its parameters, configure references, or run it
                      independently.
                    </Empty>
                  )}
                </section>
              </div>
              <details className="panel details-panel">
                <summary>
                  Run overrides · applied after every saved configuration layer
                </summary>
                <JsonEditor
                  label="Run overrides JSON, keyed by invocation ID"
                  value={overrides}
                  onChange={(v) => {
                    setOverrides(v);
                    setPlan(undefined);
                  }}
                  rows={6}
                />
                <p className="help">
                  Values are passed to the engine for this run only. Use $env
                  references for secrets.
                </p>
              </details>
              <details className="panel details-panel">
                <summary>
                  Selected source JSON · unknown fields preserved
                </summary>
                <JsonEditor
                  label="Selected layer JSON"
                  value={draft}
                  onChange={(v) => {
                    setDraft(v);
                    setPlan(undefined);
                  }}
                  disabled={locked || !layer || busy}
                />
                <p className="help">
                  Save the explicit source layer, then preflight. The full JSON
                  document is retained; visual edits replace only the chosen
                  plot’s step list.
                </p>
              </details>
              {plan && <PlanDetails plan={plan} />}
            </>
          )}

          {project && view === "layers" && (
            <>
              <div className="two-column">
                <section className="panel">
                  <div className="panel-heading">
                    <h2>Source layer</h2>
                    <Badge>{layerId}</Badge>
                  </div>
                  <div className="panel-body">
                    <JsonEditor
                      label="Editable layer JSON"
                      value={draft}
                      onChange={(v) => {
                        setDraft(v);
                        setPlan(undefined);
                      }}
                      disabled={locked || !layer || busy}
                      rows={22}
                    />
                    {draftError && (
                      <p role="alert" className="field-error">
                        {draftError}
                      </p>
                    )}
                    <p className="help">
                      Objects merge recursively. Arrays replace completely.
                      Omitted, null, false, zero, and [] remain distinct. Saving
                      never flattens effective values into this layer.
                    </p>
                    <RemoveOverride
                      disabled={locked || busy || !layer || !draftObject}
                      onRemove={(pointer) =>
                        protectedAction(async () => {
                          setDraft(
                            pretty(removeOverride(parseObject(draft), pointer)),
                          );
                        })
                      }
                    />
                  </div>
                </section>
                <section className="panel">
                  <div className="panel-heading">
                    <h2>Effective configuration</h2>
                    <Badge>Engine resolved</Badge>
                  </div>
                  <div className="panel-body">
                    <p className="help">
                      This is the last saved result, computed by PowerShell.
                      Secret references remain references.
                    </p>
                    <JsonView
                      value={configuration?.Configuration}
                      label="Engine effective configuration"
                    />
                    <details>
                      <summary>Exact file provenance</summary>
                      <JsonView
                        value={configuration?.Sources}
                        label="Configuration provenance"
                      />
                    </details>
                    <details>
                      <summary>Ordered source files</summary>
                      <JsonView value={configuration?.Layers} />
                    </details>
                  </div>
                </section>
              </div>
              <FilesPanel
                pid={pid}
                onError={setError}
                onUploaded={(path) =>
                  setSuccess(
                    `Uploaded to service-host project: ${path}. Reference this path explicitly in configuration.`,
                  )
                }
              />
            </>
          )}

          {project && view === "runs" && (
            <RunHistory
              runs={runs}
              selected={run}
              events={events}
              connection={connection}
              onSelect={(record) => setRun(record)}
              onRefresh={() =>
                void protectedAction(async () => {
                  await refreshRuns();
                })
              }
              onCancel={() =>
                void protectedAction(async () => {
                  if (!run) return;
                  setRun(
                    await post<Run>(
                      `${pid}/runs/${segment(run.id)}/cancel`,
                      {},
                    ),
                  );
                  await refreshRuns();
                })
              }
              busy={busy}
            />
          )}

          {project && view === "wizard" && !wizard && (
            <section className="panel">
              <Empty title="No guided form in this project">
                Add a declarative wizard to the portable project definition, or
                create a project with the generic sample.
              </Empty>
            </section>
          )}
          {project && view === "wizard" && wizard && (
            <section className="panel wizard-panel">
              <div className="panel-heading">
                <div>
                  <p className="eyebrow">DECLARATIVE PROJECT TEMPLATE</p>
                  <h2>{wizard.title}</h2>
                </div>
                <Badge>Real engine</Badge>
              </div>
              <div className="panel-body">
                <p className="muted">{wizard.description}</p>
                <ol className="wizard-stages">
                  {["Target", "Settings", "Preflight", "Run", "Result"].map(
                    (name, index) => (
                      <li
                        key={name}
                        className={
                          index === wizardStage
                            ? "current"
                            : index < wizardStage
                              ? "done"
                              : ""
                        }
                      >
                        <span>{index < wizardStage ? "✓" : index + 1}</span>
                        {name}
                      </li>
                    ),
                  )}
                </ol>
                {wizardStage === 0 && (
                  <>
                    <h3>Choose the execution target</h3>
                    <div className="target-option">
                      <span className="live-dot" />
                      <div>
                        <strong>{runner?.displayName}</strong>
                        <p>
                          {runner?.os} · {runner?.identity}
                        </p>
                        <small>
                          The service host executes this plot. Additional
                          machine agents are a later capability.
                        </small>
                      </div>
                    </div>
                    {wizard.groups
                      .filter((group) =>
                        group.id.toLowerCase().includes("target"),
                      )
                      .map((group) => (
                        <WizardFields
                          key={group.id}
                          group={group}
                          values={wizardValues}
                          onChange={setWizardValues}
                        />
                      ))}
                    <button
                      className="primary"
                      onClick={() => setWizardStage(1)}
                    >
                      Continue to settings →
                    </button>
                  </>
                )}
                {wizardStage === 1 && (
                  <>
                    <h3>Configure the sample</h3>
                    {wizard.groups
                      .filter(
                        (group) => !group.id.toLowerCase().includes("target"),
                      )
                      .map((group) => (
                        <WizardFields
                          key={group.id}
                          group={group}
                          values={wizardValues}
                          onChange={setWizardValues}
                        />
                      ))}
                    <p className="help">
                      These answers update ordinary project configuration. They
                      do not create a separate execution system.
                    </p>
                    <div className="button-row">
                      <button onClick={() => setWizardStage(0)}>Back</button>
                      <button
                        className="primary"
                        disabled={busy || locked || dirty}
                        onClick={() =>
                          void protectedAction(async () => {
                            const currentLayer = await api<Layer>(
                              `${pid}/layers/${segment(wizard.layer || "project")}`,
                            );
                            await post<Layer>(`${pid}/wizard`, {
                              etag: currentLayer.etag,
                              values: wizardValues,
                            });
                            if (layerId === (wizard.layer || "project"))
                              await loadLayer();
                            await loadConfiguration();
                            setWizardStage(2);
                          })
                        }
                      >
                        Save answers →
                      </button>
                    </div>
                  </>
                )}
                {wizardStage === 2 && (
                  <>
                    <h3>Inspect before execution</h3>
                    <Notice>
                      Static preflight checks configuration, installed steps,
                      and ordered output dependencies. It does not contact
                      external services.
                    </Notice>
                    <button
                      className="primary"
                      disabled={busy || locked}
                      onClick={() =>
                        void protectedAction(async () => {
                          const result = await post<{ engine: Plan }>(
                            `${pid}/plan`,
                            { plot: wizard.plot, environment, overrides: {} },
                          );
                          setWizardPlan(result.engine);
                        })
                      }
                    >
                      Run static preflight
                    </button>
                    {wizardPlan && (
                      <>
                        <PlanDetails plan={wizardPlan} />
                        <div className="button-row">
                          <button onClick={() => setWizardStage(1)}>
                            Back to settings
                          </button>
                          <button
                            className="primary"
                            onClick={() => setWizardStage(3)}
                          >
                            Continue to run →
                          </button>
                        </div>
                      </>
                    )}
                  </>
                )}
                {wizardStage === 3 && (
                  <>
                    <h3>Ready to run {wizard.plot}</h3>
                    <p>
                      The worker receives a fixed snapshot of configuration and
                      package versions. Closing this browser does not stop it.
                    </p>
                    <button
                      className="primary"
                      disabled={busy || locked}
                      onClick={() =>
                        void protectedAction(async () => {
                          const record = await post<Run>(`${pid}/runs`, {
                            plot: wizard.plot,
                            environment,
                            overrides: {},
                            whatIf: false,
                          });
                          setRun(record);
                          setWizardRunId(record.id);
                          await refreshRuns();
                          setWizardStage(4);
                        })
                      }
                    >
                      ▶ Run sample installation
                    </button>
                  </>
                )}
                {wizardStage === 4 && (
                  <>
                    <h3>Installation result</h3>
                    {run?.id === wizardRunId ? (
                      <>
                        <div className="run-title">
                          <span data-testid="wizard-run-status">
                            <Badge>{run.status}</Badge>
                          </span>
                          <code>{run.id}</code>
                        </div>
                        <RunResults run={run} />
                        <p className="help">{connection}</p>
                      </>
                    ) : (
                      <Notice>
                        The run record is in Run history. Reopen its durable ID
                        to reconnect.
                      </Notice>
                    )}
                    <div className="button-row">
                      <button onClick={() => setView("runs")}>
                        Open run history
                      </button>
                      <button
                        onClick={() => {
                          changePlot(wizard.plot);
                          setView("plot");
                        }}
                      >
                        Open ordinary plot editor
                      </button>
                    </div>
                    <p className="help">
                      The sample writes to the configured target on the service
                      host. Review its output and remove only the sample
                      artifacts you created.
                    </p>
                  </>
                )}
              </div>
            </section>
          )}

          {view === "secrets" && (
            <SecretsPanel onError={setError} onSuccess={setSuccess} />
          )}
          <footer>
            Plot Manager{" "}
            <span>
              Shared desktop & browser workspace · execution stays on the
              service host
            </span>
          </footer>
        </main>
      </div>
    </div>
  );
}

function Workspace({
  projects,
  project,
  onSelect,
  effective,
  catalogCount,
  onCreate,
  onOpen,
  onEnvironment,
  onBrowse,
  onNavigate,
  busy,
}: {
  projects: Project[];
  project?: Project;
  effective: JsonObject;
  catalogCount: number;
  busy: boolean;
  onSelect: (p: Project) => void;
  onCreate: (
    name: string,
    directory: string,
    template: boolean,
  ) => Promise<void>;
  onOpen: (directory: string) => Promise<void>;
  onEnvironment: (name: string) => Promise<void>;
  onBrowse: () => void;
  onNavigate: (view: View) => void;
}) {
  const [name, setName] = useState(""),
    [directory, setDirectory] = useState(""),
    [template, setTemplate] = useState(true),
    [existing, setExisting] = useState(""),
    [newEnvironment, setNewEnvironment] = useState("");
  return (
    <>
      <div className="stats-grid">
        <div className="stat">
          <span>PROJECTS</span>
          <strong>{projects.length.toString().padStart(2, "0")}</strong>
          <small>In your workspace</small>
        </div>
        <div className="stat">
          <span>INSTALLED STEPS</span>
          <strong>{catalogCount.toString().padStart(2, "0")}</strong>
          <small>From package manifests</small>
        </div>
        <div className="stat">
          <span>ACTIVE PLOTS</span>
          <strong>
            {plotNames(effective).length.toString().padStart(2, "0")}
          </strong>
          <small>Saved effective configuration</small>
        </div>
      </div>
      <div className="two-column">
        <section className="panel">
          <div className="panel-heading">
            <h2>Your projects</h2>
            <span className="count">{projects.length}</span>
          </div>
          {projects.length ? (
            <div className="project-list">
              {projects.map((item) => (
                <button
                  className={
                    project?.id === item.id
                      ? "project-item selected"
                      : "project-item"
                  }
                  key={item.id}
                  onClick={() => onSelect(item)}
                >
                  <span className="project-icon">▰</span>
                  <span>
                    <strong>{item.name}</strong>
                    <small>{item.directory}</small>
                  </span>
                  <span aria-hidden="true">→</span>
                </button>
              ))}
            </div>
          ) : (
            <Empty title="A fresh workspace">
              Create a generic sample project or open a portable project
              definition on this service host.
            </Empty>
          )}
          <div className="panel-body">
            <form
              onSubmit={(e) => {
                e.preventDefault();
                void onOpen(existing);
              }}
            >
              <label className="field">
                Open existing project on the service host
                <input
                  placeholder="Directory containing plot-project.json"
                  value={existing}
                  onChange={(e) => setExisting(e.target.value)}
                  required
                />
              </label>
              <button disabled={busy}>Open project</button>
            </form>
          </div>
        </section>
        <section className="panel">
          <div className="panel-heading">
            <h2>Create a project</h2>
            <Badge>Portable JSON</Badge>
          </div>
          <form
            className="panel-body"
            onSubmit={(e) => {
              e.preventDefault();
              void onCreate(name, directory, template);
            }}
          >
            <label className="field">
              Project name
              <input
                placeholder="My first installation"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
            </label>
            <label className="field">
              Service-host directory (optional)
              <input
                placeholder="Automatic safe folder under the allowed root"
                value={directory}
                onChange={(e) => setDirectory(e.target.value)}
              />
            </label>
            <label className="checkbox">
              <input
                type="checkbox"
                checked={template}
                onChange={(e) => setTemplate(e.target.checked)}
              />
              Include the generic guided installation
            </label>
            <p className="help">
              The sample uses generic text and filesystem steps. Its target and
              message are stored as normal configuration.
            </p>
            <button className="primary" disabled={busy}>
              + Create project
            </button>
          </form>
        </section>
      </div>
      {project && (
        <section className="panel">
          <div className="panel-heading">
            <h2>Continue with {project.name}</h2>
            <Badge>Service-host execution</Badge>
          </div>
          <div className="panel-body">
            <div className="quick-links">
              <button onClick={() => onNavigate("wizard")}>
                <span>✧</span>
                <strong>Guided setup</strong>
                <small>Target → settings → run</small>
              </button>
              <button onClick={() => onNavigate("plot")}>
                <span>☷</span>
                <strong>Build your plot</strong>
                <small>Schema-driven step editor</small>
              </button>
              <button onClick={onBrowse}>
                <span>▱</span>
                <strong>Inspect configuration</strong>
                <small>Layers and file provenance</small>
              </button>
            </div>
            <form
              className="inline-form"
              onSubmit={(e) => {
                e.preventDefault();
                void onEnvironment(newEnvironment);
              }}
            >
              <label className="field">
                Add environment
                <input
                  placeholder="staging"
                  value={newEnvironment}
                  onChange={(e) => setNewEnvironment(e.target.value)}
                  required
                  pattern="[A-Za-z0-9_-]+"
                />
              </label>
              <button disabled={busy}>Create environment</button>
            </form>
            <details>
              <summary>Portable project definition</summary>
              <JsonView value={project.definition} />
            </details>
          </div>
        </section>
      )}
    </>
  );
}

function DefinitionEditor({
  pid,
  locked,
  onError,
  onSaved,
}: {
  pid: string;
  locked: boolean;
  onError: (error: string) => void;
  onSaved: () => Promise<void>;
}) {
  const [document, setDocument] = useState<{
      etag: string;
      data: JsonObject;
    }>(),
    [text, setText] = useState(""),
    [busy, setBusy] = useState(false);
  const load = useCallback(async () => {
    const result = await api<{ etag: string; data: JsonObject }>(
      `${pid}/definition`,
    );
    setDocument(result);
    setText(pretty(result.data));
  }, [pid]);
  useEffect(() => {
    let disposed = false;
    void api<{ etag: string; data: JsonObject }>(`${pid}/definition`)
      .then((result) => {
        if (!disposed) {
          setDocument(result);
          setText(pretty(result.data));
        }
      })
      .catch((e) => {
        if (!disposed) onError(errText(e));
      });
    return () => {
      disposed = true;
    };
  }, [pid]);
  return (
    <details className="panel details-panel">
      <summary>
        Edit portable project definition · configuration paths and declarative
        wizard
      </summary>
      <p className="help">
        Paths are relative to the project directory. Keep credentials and
        unnecessary machine details outside this file. Unknown properties are
        retained. Saving checks the definition version and project run lock.
      </p>
      <JsonEditor
        label="Portable project definition JSON"
        value={text}
        onChange={setText}
        disabled={locked || busy}
        rows={12}
      />
      <div className="button-row">
        <button
          disabled={busy}
          onClick={() => {
            if (
              !document ||
              text === pretty(document.data) ||
              window.confirm("Discard unsaved definition changes?")
            )
              void load().catch((e) => onError(errText(e)));
          }}
        >
          Reload definition
        </button>
        <button
          className="primary"
          disabled={
            locked || busy || !document || text === pretty(document.data)
          }
          onClick={() => {
            setBusy(true);
            void (async () => {
              try {
                const result = await put<{ etag: string; data: JsonObject }>(
                  `${pid}/definition`,
                  { etag: document?.etag, data: parseObject(text) },
                );
                setDocument(result);
                setText(pretty(result.data));
                await onSaved();
              } catch (e) {
                onError(errText(e));
              } finally {
                setBusy(false);
              }
            })();
          }}
        >
          Save definition
        </button>
      </div>
    </details>
  );
}

function StepCatalog({
  catalog,
  onAdd,
  disabled,
}: {
  catalog: CatalogStep[];
  onAdd: (step: CatalogStep) => void;
  disabled: boolean;
}) {
  const [search, setSearch] = useState("");
  return (
    <div className="catalog">
      <h3>Installed step catalog</h3>
      <input
        aria-label="Search installed steps"
        placeholder="Search package or step…"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />
      <div className="catalog-list">
        {catalog
          .filter((step) =>
            `${step.Id} ${step.Description || ""}`
              .toLowerCase()
              .includes(search.toLowerCase()),
          )
          .map((step) => (
            <button
              key={step.Id}
              onClick={() => onAdd(step)}
              disabled={disabled || step.Supported === false}
              title={step.Description || step.Id}
            >
              <span>
                <strong>{step.Id}</strong>
                <small>
                  {step.Package} {step.Version}
                  {step.Platform && step.Platform !== "Any"
                    ? ` · ${step.Platform}`
                    : ""}
                </small>
                {step.Description && <small>{step.Description}</small>}
                {step.Tools?.map((tool) => (
                  <small
                    className={tool.Available ? "" : "field-error"}
                    key={tool.Name}
                  >
                    {tool.Name}:{" "}
                    {tool.Available ? "available" : "missing on runner"}
                  </small>
                ))}
                {step.RequiredTools?.length ? (
                  <small>Tools: {step.RequiredTools.join(", ")}</small>
                ) : null}
              </span>
              {step.Supported === false ? (
                <Badge>Unsupported</Badge>
              ) : (
                <span>+</span>
              )}
            </button>
          ))}
      </div>
    </div>
  );
}

function RemoveOverride({
  onRemove,
  disabled,
}: {
  onRemove: (pointer: string) => Promise<void>;
  disabled: boolean;
}) {
  const [pointer, setPointer] = useState("");
  return (
    <form
      className="inline-form"
      onSubmit={(e) => {
        e.preventDefault();
        void onRemove(pointer);
      }}
    >
      <label className="field">
        Restore inheritance at JSON pointer
        <input
          placeholder="/Values/Message"
          value={pointer}
          onChange={(e) => setPointer(e.target.value)}
          required
          disabled={disabled}
        />
      </label>
      <button disabled={disabled}>Remove override</button>
    </form>
  );
}

function PlanDetails({ plan }: { plan: Plan }) {
  return (
    <section className="panel plan-panel">
      <div className="panel-heading">
        <h2>Engine preflight</h2>
        <Badge>Succeeded</Badge>
      </div>
      <div className="panel-body">
        <p className="help">
          File origins and parameter-setting layers are reported separately by
          the engine. Secret parameters are redacted.
        </p>
        {plan.Steps?.map((step) => (
          <details key={step.Id}>
            <summary>
              {step.Id} <span className="muted">· {step.Step}</span>
            </summary>
            <div className="two-column">
              <div>
                <h4>Effective invocation settings</h4>
                <JsonView value={step.Settings} />
              </div>
              <div>
                <h4>Setting layers</h4>
                <JsonView value={step.Sources} />
                <h4>Exact file / setting origins</h4>
                <JsonView value={step.Origins} />
              </div>
            </div>
          </details>
        ))}
        <details>
          <summary>Complete plan response</summary>
          <JsonView value={plan} />
        </details>
      </div>
    </section>
  );
}

function RunHistory({
  runs,
  selected,
  events,
  connection,
  onSelect,
  onRefresh,
  onCancel,
  busy,
}: {
  runs: Run[];
  selected?: Run;
  events: RunEvent[];
  connection: string;
  onSelect: (run: Run) => void;
  onRefresh: () => void;
  onCancel: () => void;
  busy: boolean;
}) {
  return (
    <div className="history-layout">
      <section className="panel">
        <div className="panel-heading">
          <h2>
            Runs <span className="count">{runs.length}</span>
          </h2>
          <button className="small" onClick={onRefresh}>
            Refresh
          </button>
        </div>
        {!runs.length && (
          <Empty title="No runs yet">
            Run a saved plot or start with the guided sample.
          </Empty>
        )}
        <div className="run-list">
          {runs.map((run) => (
            <button
              key={run.id}
              className={
                selected?.id === run.id ? "run-item selected" : "run-item"
              }
              onClick={() => onSelect(run)}
            >
              <span>
                <strong>
                  {run.plot}
                  {run.invocationId ? ` / ${run.invocationId}` : ""}
                </strong>
                <small>{stamp(run.createdAt)}</small>
                <code>{run.id.slice(0, 12)}</code>
              </span>
              <Badge>
                {run.whatIf ? `Preview · ${run.status}` : run.status}
              </Badge>
            </button>
          ))}
        </div>
      </section>
      <section className="panel">
        {selected ? (
          <>
            <div className="panel-heading">
              <div>
                <p className="eyebrow">
                  {selected.whatIf
                    ? "WHATIF PREVIEW · NO STEP COMMANDS"
                    : "RUN RECORD"}
                </p>
                <h2>{selected.plot}</h2>
              </div>
              <Badge>{selected.status}</Badge>
            </div>
            <div className="panel-body">
              <div className="run-metadata">
                <label>
                  Run ID<code>{selected.id}</code>
                </label>
                <label>
                  Environment<span>{selected.environment}</span>
                </label>
                <label>
                  Started<span>{stamp(selected.startedAt)}</span>
                </label>
                <label>
                  Completed<span>{stamp(selected.completedAt)}</span>
                </label>
              </div>
              <p className="connection-state">
                <span className="live-dot" />
                {connection}
              </p>
              {active(selected) && (
                <button
                  className="danger small"
                  disabled={busy}
                  onClick={onCancel}
                >
                  Request stop · terminate worker
                </button>
              )}
              {["Cancelled", "Interrupted"].includes(selected.status) && (
                <Notice kind="warning">
                  {selected.status} means the worker stopped or service
                  restarted. No automatic rollback occurred; a remote operation
                  may still be running.
                </Notice>
              )}
              <RunResults run={selected} />
              <details open className="event-log">
                <summary>
                  Live event log <span className="count">{events.length}</span>
                </summary>
                <ol>
                  {events.map((event) => (
                    <li key={event.cursor}>
                      <time>
                        {new Date(event.timestamp).toLocaleTimeString()}
                      </time>
                      <code>#{event.cursor}</code>
                      <strong>{event.type}</strong>
                      <span>
                        {event.invocationId} {event.step}
                      </span>
                      <span>
                        {event.status}{" "}
                        {event.durationMs !== undefined
                          ? duration(event.durationMs)
                          : ""}
                      </span>
                    </li>
                  ))}
                </ol>
              </details>
              <details>
                <summary>
                  Run snapshot · immutable configuration and package
                  fingerprints
                </summary>
                <JsonView value={selected.snapshot} />
              </details>
              <p className="help">
                Closing this page leaves the run active. This URL contains only
                project and run IDs; reopen it and authenticate to replay
                durable events.
              </p>
              <Notice>
                Stop terminates the worker process tree. External services may
                continue operations already started. A stop request does not
                roll back changes.
              </Notice>
            </div>
          </>
        ) : (
          <Empty title="Select a run">
            Reconnect to live progress or inspect a stored result.
          </Empty>
        )}
      </section>
    </div>
  );
}

function RunResults({ run }: { run: Run }) {
  const engine = object(run.engine) ? run.engine : undefined;
  const steps = run.steps?.length
    ? run.steps
    : engine && Array.isArray(engine.Steps)
      ? (engine.Steps as unknown as Run["steps"])
      : [];
  return (
    <>
      {run.error && <Notice kind="error">{run.error}</Notice>}
      {steps?.length ? (
        <div className="results-table">
          <table>
            <thead>
              <tr>
                <th>Invocation</th>
                <th>State</th>
                <th>Duration</th>
              </tr>
            </thead>
            <tbody>
              {steps.map((step, i) => (
                <tr key={step.id || step.Id || step.invocationId || i}>
                  <td>
                    <strong>{step.id || step.Id || step.invocationId}</strong>
                    <small>{step.step || step.Step}</small>
                  </td>
                  <td>
                    <Badge>{step.status || step.Status}</Badge>
                  </td>
                  <td>{duration(step.durationMs ?? step.DurationMs)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <p className="muted">
          {active(run)
            ? "Waiting for the first step event…"
            : "No step result records."}
        </p>
      )}
      <details open={!active(run)}>
        <summary>Structured result</summary>
        <JsonView value={run.engine ?? { status: run.status }} />
      </details>
    </>
  );
}

function WizardFields({
  group,
  values,
  onChange,
}: {
  group: Wizard["groups"][number];
  values: JsonObject;
  onChange: (values: JsonObject) => void;
}) {
  return (
    <fieldset className="wizard-fields">
      <legend>{group.title}</legend>
      {group.fields.map((field) => (
        <WizardInput
          key={field.key}
          field={field}
          value={values[field.key]}
          onChange={(value) => {
            const next = { ...values };
            if (value === undefined) delete next[field.key];
            else next[field.key] = value;
            onChange(next);
          }}
        />
      ))}
    </fieldset>
  );
}

function WizardInput({
  field,
  value,
  onChange,
}: {
  field: Wizard["groups"][number]["fields"][number];
  value: Json | undefined;
  onChange: (value: Json | undefined) => void;
}) {
  const [text, setText] = useState(pretty(value) ?? ""),
    [error, setError] = useState("");
  useEffect(() => {
    setText(pretty(value) ?? "");
    setError("");
  }, [value]);
  return (
    <label className="field">
      {field.label}
      {field.required ? " *" : ""}
      {field.type === "bool" ? (
        <select
          value={value === undefined ? "" : String(value)}
          required={field.required}
          onChange={(e) =>
            onChange(
              e.target.value === "" ? undefined : e.target.value === "true",
            )
          }
        >
          <option value="">Select a value</option>
          <option value="false">false</option>
          <option value="true">true</option>
        </select>
      ) : ["array", "object"].includes(field.type) ? (
        <textarea
          className="code"
          rows={4}
          value={text}
          onChange={(e) => {
            setText(e.target.value);
            setError("JSON not applied. Finish editing and leave the field.");
          }}
          onBlur={() => {
            try {
              const parsed = parseJson<Json>(text);
              if (
                field.type === "array"
                  ? !Array.isArray(parsed)
                  : !object(parsed)
              )
                throw new Error(`Use a JSON ${field.type}.`);
              onChange(parsed);
              setError("");
            } catch (e) {
              setError(errText(e));
            }
          }}
        />
      ) : (
        <input
          value={
            typeof value === "string" ||
            typeof value === "number" ||
            isLosslessNumber(value)
              ? String(value)
              : ""
          }
          type={
            field.type === "int" || field.type === "number" ? "number" : "text"
          }
          required={field.required}
          onChange={(e) =>
            onChange(
              field.type === "int" || field.type === "number"
                ? e.target.value === ""
                  ? undefined
                  : numberInput(e.target.value)
                : e.target.value,
            )
          }
        />
      )}
      {field.description && <small className="help">{field.description}</small>}
      {field.settingPath && (
        <small className="help">Configuration: {field.settingPath}</small>
      )}
      {error && (
        <small className="field-error" role="alert">
          {error}
        </small>
      )}
    </label>
  );
}

function FilesPanel({
  pid,
  onError,
  onUploaded,
}: {
  pid: string;
  onError: (error: string) => void;
  onUploaded: (path: string) => void;
}) {
  const [path, setPath] = useState(""),
    [listing, setListing] = useState<{
      path: string;
      allowedRoot: string;
      entries: { name: string; path: string; isDirectory: boolean }[];
    }>();
  const [uploading, setUploading] = useState(false);
  const browse = async (selectedPath: string) => {
    try {
      const result = await api<typeof listing>(
        `/browse?path=${segment(selectedPath)}`,
      );
      setListing(result);
      setPath(result?.path || "");
    } catch (e) {
      onError(errText(e));
    }
  };
  return (
    <section className="panel">
      <div className="panel-heading">
        <h2>Files & locations</h2>
        <Badge>Explicit transfer</Badge>
      </div>
      <div className="panel-body two-column">
        <div>
          <h3>Browse on the runner</h3>
          <p className="help">
            These paths belong to the service host and its allowed project root.
            Selecting a path does not upload anything from your computer.
          </p>
          <form
            className="inline-form"
            onSubmit={(e) => {
              e.preventDefault();
              void browse(path);
            }}
          >
            <label className="field">
              Service-host path
              <input
                value={path}
                onChange={(e) => setPath(e.target.value)}
                placeholder="Allowed project root"
              />
            </label>
            <button>Browse runner</button>
          </form>
          {listing && (
            <>
              <p className="help">
                Allowed root: <code>{listing.allowedRoot}</code>
              </p>
              <ul className="file-list">
                {listing.entries.map((entry) => (
                  <li key={entry.path}>
                    <button
                      onClick={() => {
                        if (entry.isDirectory) void browse(entry.path);
                        else setPath(entry.path);
                      }}
                    >
                      {entry.isDirectory ? "▰" : "▱"} {entry.name}
                    </button>
                    <code>{entry.path}</code>
                  </li>
                ))}
              </ul>
            </>
          )}
        </div>
        <div>
          <h3>Upload a file from this computer</h3>
          <p className="help">
            The selected browser file is copied into this project’s uploads
            directory on the service host. It is a deliberate file transfer.
          </p>
          <label className="field">
            Local browser file
            <input
              type="file"
              disabled={uploading}
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (!file) return;
                const input = e.currentTarget;
                setUploading(true);
                const reader = new FileReader();
                reader.onload = () => {
                  void (async () => {
                    try {
                      const contentBase64 = String(reader.result).split(",")[1];
                      const result = await post<{
                        path: string;
                        relativePath: string;
                      }>(`${pid}/uploads`, { name: file.name, contentBase64 });
                      onUploaded(result.relativePath);
                    } catch (error) {
                      onError(errText(error));
                    } finally {
                      input.value = "";
                      setUploading(false);
                    }
                  })();
                };
                reader.onerror = () => {
                  onError("The browser could not read the selected file.");
                  setUploading(false);
                };
                reader.readAsDataURL(file);
              }}
            />
          </label>
          {uploading && <p role="status">Transferring file…</p>}
          <Notice>
            Upload ordinary input files only. Store credentials in Runner
            secrets; keep private keys outside versioned project configuration.
          </Notice>
        </div>
      </div>
    </section>
  );
}

function SecretsPanel({
  onError,
  onSuccess,
}: {
  onError: (error: string) => void;
  onSuccess: (message: string) => void;
}) {
  const [secrets, setSecrets] = useState<{ name: string; reference: Json }[]>(
      [],
    ),
    [name, setName] = useState(""),
    [value, setValue] = useState(""),
    [busy, setBusy] = useState(false);
  const refresh = useCallback(async () => {
    setSecrets((await api<{ secrets: typeof secrets }>("/secrets")).secrets);
  }, []);
  useEffect(() => {
    void refresh().catch((e) => onError(errText(e)));
  }, [refresh]);
  return (
    <section className="panel">
      <div className="panel-heading">
        <h2>Service-local secret references</h2>
        <Badge>Values never returned</Badge>
      </div>
      <div className="panel-body">
        <Notice>
          Secrets belong to the service host’s runner identity. GUI/API HTTPS
          certificates, step connection certificates, and certificates installed
          by a plot are separate concerns.
        </Notice>
        <form
          className="secret-form"
          onSubmit={(e) => {
            e.preventDefault();
            setBusy(true);
            void (async () => {
              try {
                const result = await put<{ reference: Json }>(
                  `/secrets/${segment(name)}`,
                  { value },
                );
                setValue("");
                setName("");
                await refresh();
                onSuccess(
                  `Secret stored locally. Use ${stringifyJson(result.reference)} in a parameter.`,
                );
              } catch (error) {
                onError(errText(error));
              } finally {
                setBusy(false);
              }
            })();
          }}
        >
          <label className="field">
            Secret name
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoComplete="off"
              pattern="[A-Za-z][A-Za-z0-9_]*"
              required
            />
          </label>
          <label className="field">
            Secret value
            <input
              type="password"
              value={value}
              onChange={(e) => setValue(e.target.value)}
              autoComplete="new-password"
              required
            />
          </label>
          <button className="primary" disabled={busy}>
            Store on service host
          </button>
        </form>
        <p className="help">
          The value is cleared from this form after saving. Configuration stores
          only the $env reference. TLS verification remains enabled by default.
        </p>
        {secrets.length ? (
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Configuration reference</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {secrets.map((secret) => (
                <tr key={secret.name}>
                  <td>{secret.name}</td>
                  <td>
                    <code>{stringifyJson(secret.reference)}</code>
                  </td>
                  <td>
                    <button
                      className="small danger"
                      onClick={() => {
                        if (
                          !window.confirm(
                            `Remove secret ${secret.name} from the service host? Existing configuration references may stop resolving.`,
                          )
                        )
                          return;
                        void api(`/secrets/${segment(secret.name)}`, {
                          method: "DELETE",
                        })
                          .then(refresh)
                          .catch((e) => onError(errText(e)));
                      }}
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <Empty title="No stored secrets">
            Add a named value to receive its environment reference.
          </Empty>
        )}
      </div>
    </section>
  );
}
