import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import { pretty, object, type Json, type Parameter } from "./model";
import {
  isLosslessNumber,
  numberInput,
  parseJson,
  stringifyJson,
} from "./json";

export function Notice({
  children,
  kind = "info",
}: {
  children: ReactNode;
  kind?: "info" | "error" | "success" | "warning";
}) {
  return (
    <div
      className={`notice ${kind}`}
      role={kind === "error" ? "alert" : "status"}
    >
      {children}
    </div>
  );
}
export function Badge({ children }: { children: ReactNode }) {
  return (
    <span className={`badge ${String(children).toLowerCase()}`}>
      {children}
    </span>
  );
}
export function JsonView({
  value,
  label = "JSON",
}: {
  value: unknown;
  label?: string;
}) {
  return (
    <pre className="json-view" aria-label={label}>
      {pretty(value)}
    </pre>
  );
}
export function JsonEditor({
  value,
  onChange,
  label,
  rows = 15,
  disabled = false,
}: {
  value: string;
  onChange: (v: string) => void;
  label: string;
  rows?: number;
  disabled?: boolean;
}) {
  return (
    <label className="field">
      <span>{label}</span>
      <textarea
        className="code"
        spellCheck={false}
        rows={rows}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        disabled={disabled}
      />
    </label>
  );
}
export function Empty({
  title,
  children,
}: {
  title: string;
  children?: ReactNode;
}) {
  return (
    <div className="empty">
      <span className="empty-mark" aria-hidden="true">
        ◇
      </span>
      <h3>{title}</h3>
      {children && <p>{children}</p>}
    </div>
  );
}
type ValueMode = "inherit" | "value" | "json" | "reference" | "secret" | "null";
function modeOf(value: Json | undefined): ValueMode {
  if (value === undefined) return "inherit";
  if (value === null) return "null";
  if (isLosslessNumber(value)) return "json";
  if (object(value) && typeof value.$ref === "string") return "reference";
  if (object(value) && typeof value.$env === "string") return "secret";
  if (typeof value === "object") return "json";
  return "value";
}

export function ParameterField({
  name,
  schema,
  value,
  onChange,
  onValidityChange,
  references = [],
  disabled = false,
}: {
  name: string;
  schema: Parameter;
  value: Json | undefined;
  onChange: (value: Json | undefined) => void;
  onValidityChange?: (valid: boolean) => void;
  references?: string[];
  disabled?: boolean;
}) {
  const [mode, setMode] = useState<ValueMode>(modeOf(value));
  const [text, setText] = useState(pretty(value) ?? "");
  const [error, setError] = useState("");
  const id = useId();
  const validity = useRef(onValidityChange);
  validity.current = onValidityChange;
  const savedText = pretty(value);
  const report = (message = "") => {
    setError(message);
    validity.current?.(!message);
  };
  useEffect(() => {
    setMode(modeOf(value));
    setText(pretty(value) ?? "");
    setError("");
    validity.current?.(true);
  }, [name, savedText]);
  const changeMode = (next: ValueMode) => {
    setMode(next);
    report();
    switch (next) {
      case "inherit":
        onChange(undefined);
        break;
      case "null":
        onChange(null);
        break;
      case "reference":
        onChange({ $ref: references[0] || "settings.Values.Message" });
        break;
      case "secret":
        onChange({ $env: "PLOTMANAGER_SECRET_NAME" });
        break;
      case "json":
        onChange(schema.Type === "array" ? [] : {});
        break;
      default:
        onChange(
          schema.Type === "bool"
            ? false
            : schema.Type === "int"
              ? 0
              : (schema.ValidateSet?.[0] ?? ""),
        );
    }
  };
  return (
    <div className="parameter">
      <div className="parameter-label">
        <label htmlFor={`${id}-value`}>
          {name}
          {schema.Required && <span className="required"> required</span>}
        </label>
        <span>
          {schema.Type}
          {schema.Secret ? " · secret reference" : ""}
        </span>
      </div>
      {schema.Description && <p className="help">{schema.Description}</p>}
      <div className="parameter-input">
        <select
          aria-label={`${name} value source`}
          value={mode}
          onChange={(e) => changeMode(e.target.value as ValueMode)}
          disabled={disabled}
        >
          <option value="inherit">Inherited / omitted</option>
          {!schema.Secret && <option value="value">Value</option>}
          {!schema.Secret && <option value="json">JSON value</option>}
          <option value="reference">Settings / output reference</option>
          <option value="secret">Runner environment / secret</option>
          {schema.AllowNull && <option value="null">Explicit null</option>}
        </select>
        {mode === "inherit" && (
          <span className="muted inherited">
            Engine supplies inherited value
            {Object.hasOwn(schema, "Default") && !schema.Secret
              ? ` (step default: ${stringifyJson(schema.Default)})`
              : ""}
            .
          </span>
        )}
        {mode === "null" && (
          <code className="inherited">
            null — a value, distinct from omission
          </code>
        )}
        {mode === "reference" && (
          <>
            <input
              id={`${id}-value`}
              list={`${id}-references`}
              aria-label={`${name} reference`}
              value={object(value) ? String(value.$ref ?? "") : ""}
              onChange={(e) => onChange({ $ref: e.target.value })}
              disabled={disabled}
            />
            <datalist id={`${id}-references`}>
              {references.map((ref) => (
                <option key={ref} value={ref} />
              ))}
            </datalist>
          </>
        )}
        {mode === "secret" && (
          <input
            id={`${id}-value`}
            aria-label={`${name} environment variable`}
            value={object(value) ? String(value.$env ?? "") : ""}
            onChange={(e) => onChange({ $env: e.target.value })}
            disabled={disabled}
          />
        )}
        {schema.Secret && mode === "value" && (
          <span className="muted inherited">
            Literal hidden. Store it in Runner secrets and choose its
            environment reference.
          </span>
        )}
        {!schema.Secret &&
          mode === "value" &&
          (schema.ValidateSet ? (
            <select
              id={`${id}-value`}
              value={stringifyJson(value)}
              onChange={(e) => onChange(parseJson<Json>(e.target.value))}
              disabled={disabled}
            >
              {schema.ValidateSet.map((v) => (
                <option key={stringifyJson(v)} value={stringifyJson(v)}>
                  {String(v)}
                </option>
              ))}
            </select>
          ) : schema.Type === "bool" ? (
            <select
              id={`${id}-value`}
              value={String(value)}
              onChange={(e) => onChange(e.target.value === "true")}
              disabled={disabled}
            >
              <option value="false">false</option>
              <option value="true">true</option>
            </select>
          ) : (
            <input
              id={`${id}-value`}
              type={schema.Type === "int" ? "number" : "text"}
              min={schema.Minimum}
              max={schema.Maximum}
              step={schema.Type === "int" ? 1 : undefined}
              value={
                schema.Type === "int" ? text :
                typeof value === "string" || typeof value === "number"
                  ? value
                  : ""
              }
              onChange={(e) => {
                if (schema.Type === "int") {
                  setText(e.target.value);
                  if (e.target.value !== "") {
                    try {
                      onChange(numberInput(e.target.value));
                      report();
                    } catch {
                      report(
                        "Enter a complete JSON number. The last valid value is retained.",
                      );
                    }
                  } else report("Enter a complete JSON number, or choose Inherited / omitted to remove it.");
                } else onChange(e.target.value);
              }}
              disabled={disabled}
            />
          ))}
      </div>
      {mode === "json" && (
        <textarea
          id={`${id}-value`}
          className="code"
          aria-label={`${name} JSON value`}
          rows={3}
          value={text}
          disabled={disabled}
          onChange={(e) => {
            setText(e.target.value);
            report("Unapplied JSON. Finish the value and leave this field.");
          }}
          onBlur={() => {
            try {
              onChange(parseJson<Json>(text));
              report();
            } catch {
              report(
                "Invalid JSON. The last valid value is retained; correct this field before saving.",
              );
            }
          }}
        />
      )}
      {mode === "reference" && (
        <p className="help">
          Only earlier invocation outputs are available. The engine checks the
          reference and parameter type.
        </p>
      )}
      {mode === "secret" && (
        <p className="help">
          Read on the service host as its runner identity. Enter a variable
          name, never its secret value.
        </p>
      )}
      {error && (
        <p className="field-error" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
