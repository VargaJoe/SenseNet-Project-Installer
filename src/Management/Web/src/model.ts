export type Json =
  null | boolean | number | string | Json[] | { [key: string]: Json };
export type JsonObject = { [key: string]: Json };
export const object = (v: unknown): v is JsonObject =>
  v !== null && typeof v === "object" && !Array.isArray(v);
export const pretty = (value: unknown) => JSON.stringify(value, null, 2);
export const clone = <T>(value: T): T => JSON.parse(JSON.stringify(value));
export function parseObject(text: string): JsonObject {
  const value: unknown = JSON.parse(text);
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
  return data[memberKey(data, name)];
}
export function setMember(
  data: JsonObject,
  name: string,
  value: Json | undefined,
): void {
  const key = memberKey(data, name);
  if (value === undefined) delete data[key];
  else data[key] = value;
}
export function plotNames(config: JsonObject): string[] {
  const plots = member(config, "Plots");
  return object(plots) ? Object.keys(plots) : [];
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
  const original = member(plots, name) ?? member(effectivePlots, name);
  const declaredOriginalSteps = object(original)
    ? member(original, "Steps")
    : undefined;
  const originalSteps = Array.isArray(original)
    ? original
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
  const nextPlot: Json = object(original) ? clone(original) : sourceSteps;
  if (object(nextPlot)) setMember(nextPlot, "Steps", sourceSteps);
  setMember(plots, name, nextPlot);
  return next;
}
export function invocationId(step: string, ids: string[]): string {
  const base =
    step.replace(/[^a-zA-Z0-9_-]/g, "_").replace(/^[^a-zA-Z]+/, "") || "step";
  let n = 1;
  while (ids.includes(`${base}_${n}`)) n++;
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
    if (!object(current) || !(part in current))
      throw new Error("That override does not exist in this layer.");
    current = current[part];
  }
  if (!object(current) || !(parts.at(-1)! in current))
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
