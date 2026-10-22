import {
  isLosslessNumber,
  parseJson,
  stringifyJson,
  type LosslessNumber,
} from "./json";

export type Json =
  | null
  | boolean
  | number
  | LosslessNumber
  | string
  | Json[]
  | { [key: string]: Json };
export type JsonObject = { [key: string]: Json };
export const object = (v: unknown): v is JsonObject =>
  v !== null &&
  typeof v === "object" &&
  !Array.isArray(v) &&
  !isLosslessNumber(v);
export const pretty = (value: unknown) => stringifyJson(value, 2) ?? "";
export const clone = <T>(value: T): T => parseJson<T>(stringifyJson(value)!);
export function parseObject(text: string): JsonObject {
  const value: unknown = parseJson(text);
  if (!object(value)) throw new Error("The document must be a JSON object.");
  return value;
}
export interface Project {
  id: string;
  name: string;
  directory: string;
  environments: string[];
  definition: JsonObject;
  activeRunId?: string;
}
export interface LayerInfo {
  id: string;
  label: string;
  path: string;
}
export interface Layer extends LayerInfo {
  etag: string;
  data: JsonObject;
}
export interface Runner {
  id: string;
  displayName: string;
  os: string;
  identity: string;
  powerShell: string;
  mode: string;
  protocolVersion: number;
}
export interface Parameter {
  Type: string;
  Required?: boolean;
  Description?: string;
  Default?: Json;
  ValidateSet?: Json[];
  Minimum?: number;
  Maximum?: number;
  AllowNull?: boolean;
  Secret?: boolean;
}
export interface CatalogStep {
  Id: string;
  Package: string;
  Version: string;
  Description?: string;
  Platform?: string;
  Supported?: boolean;
  RequiredTools?: string[];
  Tools?: { Name: string; Available: boolean }[];
  Outputs?: Json;
  Parameters: Record<string, Parameter>;
}
export interface Invocation extends JsonObject {
  Id: string;
  Step: string;
  With: JsonObject;
}
export interface EngineConfiguration {
  Configuration: JsonObject;
  Sources: JsonObject;
  Layers?: Json;
  RawLayers?: (Layer & { file: string })[];
}
export interface PlanStep {
  Id: string;
  Step: string;
  Settings?: JsonObject;
  Sources: JsonObject;
  Origins?: JsonObject;
}
export interface Plan {
  Steps: PlanStep[];
  Configuration?: JsonObject;
  ConfigurationSources?: JsonObject;
  [key: string]: unknown;
}
export interface Run {
  id: string;
  projectId: string;
  plot: string;
  environment: string;
  invocationId?: string;
  whatIf: boolean;
  status: string;
  createdAt: string;
  startedAt?: string;
  completedAt?: string;
  steps?: RunStep[];
  engine?: Json;
  error?: string;
  snapshot?: Json;
}
export interface RunStep {
  id?: string;
  invocationId?: string;
  Id?: string;
  Step?: string;
  step?: string;
  Status?: string;
  status?: string;
  durationMs?: number;
  DurationMs?: number;
  Output?: Json;
  Error?: string;
}
export interface RunEvent {
  cursor: number;
  type: string;
  timestamp: string;
  invocationId?: string;
  step?: string;
  status?: string;
  durationMs?: number;
  [key: string]: unknown;
}
export interface WizardField {
  key: string;
  label: string;
  type: string;
  default?: Json;
  required?: boolean;
  description?: string;
  settingPath?: string;
}
export interface Wizard {
  title: string;
  description: string;
  plot: string;
  layer?: string;
  groups: { id: string; title: string; fields: WizardField[] }[];
}
// Hydrate only from the engine's saved merged document. References stay opaque:
// resolving them here could expose a runner secret or flatten a portable binding.
export function hydrateWizard(wizard: Wizard, configuration: JsonObject, targetLayer?: JsonObject) {
  const values: JsonObject = {};
  const referenced: string[] = [];
  const hasReference = (value: Json): boolean =>
    Array.isArray(value)
      ? value.some(hasReference)
      : object(value) &&
        (Object.keys(value).some((key) => ["$env", "$ref"].includes(key.toLowerCase())) ||
          Object.values(value).some(hasReference));
  const lookup = (data: JsonObject, path: string) => {
    let value: Json | undefined = data;
    for (const part of path.split(".")) {
      if (object(value) && Object.keys(value).some((key) => ["$env", "$ref"].includes(key.toLowerCase())))
        return { reference: true, value: undefined };
      value = object(value) ? member(value, part) : undefined;
    }
    return { value, reference: value !== undefined && hasReference(value) };
  };
  for (const field of wizard.groups.flatMap((group) => group.fields)) {
    const saved = lookup(configuration, field.settingPath || "");
    let value = saved.value;
    if (value === undefined && Object.hasOwn(field, "default")) value = field.default;
    if (saved.reference || (targetLayer && lookup(targetLayer, field.settingPath || "").reference) || (value !== undefined && hasReference(value))) {
      referenced.push(field.key);
      continue;
    }
    if (value !== undefined) Object.defineProperty(values, field.key, {
      value: clone(value), writable: true, enumerable: true, configurable: true,
    });
  }
  return { values, referenced };
}
export const active = (run?: Run) =>
  !!run && ["Queued", "Running"].includes(run.status);
// Native PowerShell dictionaries are case insensitive. Keep source spelling on writes.
export function memberKey(data: JsonObject, name: string): string {
  return (
    Object.keys(data).find((key) => key.toLowerCase() === name.toLowerCase()) ??
    name
  );
}
export function member(data: JsonObject, name: string): Json | undefined {
  const key = memberKey(data, name);
  return Object.hasOwn(data, key) ? data[key] : undefined;
}
export function setMember(
  data: JsonObject,
  name: string,
  value: Json | undefined,
): void {
  const key = memberKey(data, name);
  if (value === undefined) delete data[key];
  else
    Object.defineProperty(data, key, {
      value,
      writable: true,
      enumerable: true,
      configurable: true,
    });
}
export function plotNames(config: JsonObject): string[] {
  const plots = member(config, "Plots");
  return object(plots) ? Object.keys(plots) : [];
}
export function ownsPlotSteps(config: JsonObject, name: string): boolean {
  const plots = member(config, "Plots");
  const plot = object(plots) ? member(plots, name) : undefined;
  return (
    Array.isArray(plot) || (object(plot) && member(plot, "Steps") !== undefined)
  );
}
// The engine reports the winning array's file. Select that exact raw source;
// no client-side merging or copying of engine-rounded numeric metadata.
export function plotSource(
  info: EngineConfiguration,
  name: string,
): JsonObject | undefined {
  const plots = member(info.Configuration, "Plots");
  const plot = object(plots) ? member(plots, name) : undefined;
  const path = object(plot) ? `Plots.${name}.Steps` : `Plots.${name}`;
  const file = member(info.Sources, path);
  return typeof file === "string"
    ? info.RawLayers?.find((layer) => layer.file === file)?.data
    : undefined;
}
export function plotSteps(config: JsonObject, name: string): Invocation[] {
  const declaredPlots = member(config, "Plots");
  const plots = object(declaredPlots) ? declaredPlots : {};
  const plot = member(plots, name);
  const declaredSteps = object(plot) ? member(plot, "Steps") : undefined;
  const steps = Array.isArray(plot)
    ? plot
    : Array.isArray(declaredSteps)
      ? declaredSteps
      : [];
  return steps.map((step, index) => {
    if (typeof step === "string") {
      const [Step, Section] = step.split(":", 2);
      return {
        Id: `step${index + 1}`,
        Step,
        With: {},
        ...(Section ? { Section } : {}),
      };
    }
    if (!object(step))
      throw new Error(
        `Invalid invocation ${index + 1}. Use the layer JSON editor to correct it.`,
      );
    const normalized = clone(step);
    const id = member(step, "Id"),
      withValue = member(step, "With"),
      section = member(step, "Section");
    for (const field of ["Id", "Step", "With", "Section"])
      delete normalized[memberKey(normalized, field)];
    return {
      ...normalized,
      Id: typeof id === "string" ? id : `step${index + 1}`,
      Step: String(member(step, "Step") ?? ""),
      With: object(withValue) ? clone(withValue) : {},
      ...(section !== undefined ? { Section: section } : {}),
    };
  });
}
// Editing changes only the chosen plot. The engine alone resolves inheritance and validates it.
export function setPlotSteps(
  layer: JsonObject,
  effective: JsonObject,
  name: string,
  steps: Invocation[],
): JsonObject {
  const next = clone(layer);
  if (!object(member(next, "Plots"))) setMember(next, "Plots", {});
  const plots = member(next, "Plots") as JsonObject;
  const declaredEffectivePlots = member(effective, "Plots");
  const effectivePlots = object(declaredEffectivePlots)
    ? declaredEffectivePlots
    : {};
  const localOriginal = member(plots, name);
  const original = localOriginal ?? member(effectivePlots, name);
  const sourceOriginal = ownsPlotSteps(layer, name)
    ? localOriginal
    : member(effectivePlots, name);
  const declaredOriginalSteps = object(sourceOriginal)
    ? member(sourceOriginal, "Steps")
    : undefined;
  const originalSteps = Array.isArray(sourceOriginal)
    ? sourceOriginal
    : Array.isArray(declaredOriginalSteps)
      ? declaredOriginalSteps
      : [];
  const sourceSteps = steps.map((step, stepIndex) => {
    const source =
      originalSteps.find(
        (item, index) =>
          object(item) &&
          String(member(item, "Id") ?? `step${index + 1}`).toLowerCase() ===
            step.Id.toLowerCase(),
      ) ?? originalSteps[stepIndex];
    const result = clone(step);
    if (object(source))
      for (const field of ["Id", "Step", "With", "Section"]) {
        const sourceKey = memberKey(source, field);
        if (sourceKey !== field && Object.hasOwn(result, field)) {
          result[sourceKey] = result[field];
          delete result[field];
        }
      }
    return result;
  });
  const nextPlot: Json = object(original)
    ? object(localOriginal)
      ? clone(localOriginal)
      : {}
    : sourceSteps;
  if (object(nextPlot)) setMember(nextPlot, "Steps", sourceSteps);
  setMember(plots, name, nextPlot);
  return next;
}
export function createPlot(
  layer: JsonObject,
  effective: JsonObject,
  name: string,
): JsonObject {
  const trimmed = name.trim();
  if (!trimmed) throw new Error("Enter a plot name.");
  if (
    [...plotNames(layer), ...plotNames(effective)].some(
      (existing) => existing.toLowerCase() === trimmed.toLowerCase(),
    )
  ) {
    throw new Error(
      `Plot '${trimmed}' already exists. Select it to edit its steps.`,
    );
  }
  return setPlotSteps(layer, effective, trimmed, []);
}
export function invocationId(step: string, ids: string[]): string {
  const base =
    step.replace(/[^a-zA-Z0-9_-]/g, "_").replace(/^[^a-zA-Z]+/, "") || "step";
  let n = 1;
  const occupied = new Set(ids.map((id) => id.toLowerCase()));
  while (occupied.has(`${base}_${n}`.toLowerCase())) n++;
  return `${base}_${n}`;
}
export function moveStep(
  steps: Invocation[],
  index: number,
  offset: number,
): Invocation[] {
  const next = clone(steps),
    destination = index + offset;
  if (destination < 0 || destination >= next.length) return next;
  [next[index], next[destination]] = [next[destination], next[index]];
  return next;
}
// RFC 6901 paths avoid interpreting dots in user keys. Deletion restores inheritance.
export function removeOverride(data: JsonObject, pointer: string): JsonObject {
  if (!pointer.startsWith("/") || pointer === "/")
    throw new Error("Use a JSON pointer such as /Values/Message.");
  const parts = pointer
    .slice(1)
    .split("/")
    .map((x) => x.replace(/~1/g, "/").replace(/~0/g, "~"));
  const next = clone(data);
  let current: Json = next;
  for (const part of parts.slice(0, -1)) {
    if (!object(current) || !Object.hasOwn(current, part))
      throw new Error("That override does not exist in this layer.");
    current = current[part];
  }
  if (!object(current) || !Object.hasOwn(current, parts.at(-1)!))
    throw new Error(
      "That override does not exist in this layer. Array values are replaced as a whole; remove the array property.",
    );
  delete current[parts.at(-1)!];
  return next;
}
export function flatten(value: Json, prefix = ""): [string, Json][] {
  if (object(value) && Object.keys(value).length)
    return Object.entries(value).flatMap(([k, v]) =>
      flatten(v, `${prefix}/${k.replace(/~/g, "~0").replace(/\//g, "~1")}`),
    );
  return [[prefix || "/", value]];
}
export function duration(ms?: number): string {
  return ms === undefined
    ? "—"
    : ms < 1000
      ? `${ms} ms`
      : `${(ms / 1000).toFixed(1)} s`;
}
