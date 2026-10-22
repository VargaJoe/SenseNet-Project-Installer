import { describe, expect, it } from "vitest";
import {
  clone,
  invocationId,
  member,
  moveStep,
  parseObject,
  pretty,
  object,
  plotSteps,
  plotNames,
  plotSource,
  ownsPlotSteps,
  removeOverride,
  setMember,
  setPlotSteps,
  createPlot,
  hydrateWizard,
  type JsonObject,
  type Wizard,
} from "./model";
import { isLosslessNumber, stringifyJson } from "./json";

describe("source-layer editing without configuration resolution", () => {
  it("treats prototype and constructor names as ordinary own JSON fields and plot names", () => {
    const source = parseObject(
      '{"__proto__":{"toString":false,"kept":9007199254740993},"constructor":{"prototype":{"kept":true}}}',
    );
    expect(Object.getPrototypeOf(source)).toBe(Object.prototype);
    expect(Object.hasOwn(source, "__proto__")).toBe(true);
    expect(member({}, "constructor")).toBeUndefined();
    expect(member({}, "__proto__")).toBeUndefined();
    const edited = removeOverride(source, "/__proto__/toString");
    expect(stringifyJson(edited)).toBe(
      '{"__proto__":{"kept":9007199254740993},"constructor":{"prototype":{"kept":true}}}',
    );
    expect(typeof Object.prototype.toString).toBe("function");
    const withProtoPlot = createPlot({}, {}, "__proto__");
    const withConstructor = createPlot(withProtoPlot, {}, "constructor");
    expect(stringifyJson(withConstructor)).toBe(
      '{"Plots":{"__proto__":[],"constructor":[]}}',
    );
    expect(Object.getPrototypeOf(withConstructor.Plots)).toBe(Object.prototype);
    expect(plotNames(withConstructor)).toEqual(["__proto__", "constructor"]);
    expect(
      Object.hasOwn(withConstructor.Plots as JsonObject, "__proto__"),
    ).toBe(true);
  });
  it("rejects inherited JSON pointer traversal without mutating any global prototype", () => {
    const descriptor = Object.getOwnPropertyDescriptor(
      Object.prototype,
      "toString",
    );
    expect(() => removeOverride({}, "/__proto__/toString")).toThrow(
      /does not exist/,
    );
    expect(() => removeOverride({}, "/constructor/prototype")).toThrow(
      /does not exist/,
    );
    expect(() => removeOverride({ own: {} }, "/own/toString")).toThrow(
      /does not exist/,
    );
    expect(
      Object.getOwnPropertyDescriptor(Object.prototype, "toString"),
    ).toEqual(descriptor);
    expect(Object.hasOwn({}, "kept")).toBe(false);
  });
  it("rejects new plot names that duplicate saved or draft plots case-insensitively", () => {
    const effective = parseObject(
      '{"Plots":{"INSTALL":{"Steps":[{"Id":"keep","Step":"text.join","With":{"Items":[]}}]}}}',
    );
    const draft = parseObject('{"plots":{"Draft":[]},"unknown":false}');
    const beforeEffective = stringifyJson(effective),
      beforeDraft = stringifyJson(draft);
    expect(() => createPlot(draft, effective, "install")).toThrow(
      /already exists/,
    );
    expect(() => createPlot(draft, effective, " dRaFt ")).toThrow(
      /already exists/,
    );
    expect(stringifyJson(effective)).toBe(beforeEffective);
    expect(stringifyJson(draft)).toBe(beforeDraft);
  });
  it("retains unknown exact numeric tokens after unrelated visual plot edits and source roundtrip", () => {
    const source =
      '{"unknown":{"integer":9007199254740993,"decimal":0.12345678901234567890123456789,"overflow":1e400,"underflow":1e-400,"negativeZero":-0,"array":[18446744073709551616]},"Plots":{"demo":{"Steps":[{"Id":"first","Step":"text.join","With":{"Items":[]}}]}}}';
    const data = parseObject(source);
    const unknown = data.unknown as JsonObject;
    expect(isLosslessNumber(unknown.integer)).toBe(true);
    expect(object(unknown.integer)).toBe(false);
    const steps = plotSteps(data, "demo");
    steps[0].With.Items = ["unrelated edit"];
    const saved = parseObject(pretty(setPlotSteps(data, data, "demo", steps)));
    expect(stringifyJson(saved.unknown)).toBe(stringifyJson(data.unknown));
    expect(stringifyJson(saved.unknown)).toContain(
      '"integer":9007199254740993',
    );
    expect(stringifyJson(saved.unknown)).toContain(
      '"decimal":0.12345678901234567890123456789',
    );
    expect(stringifyJson(saved.unknown)).toContain('"overflow":1e400');
    expect(stringifyJson(saved.unknown)).toContain('"underflow":1e-400');
    expect(stringifyJson(saved.unknown)).toContain('"negativeZero":-0');
    expect(stringifyJson(saved.unknown)).not.toContain('"value"');
  });
  it("roundtrips unknown values and distinguishes omission, null, false, zero and empty arrays", () => {
    const data = parseObject(
      '{"extension":{"nil":null,"enabled":false,"count":0,"items":[],"date":"2026-10-21T12:34:56Z"},"Plots":{"demo":{"Unknown":{"kept":true},"Steps":[{"Id":"first","Step":"text.join","With":{"Items":[]},"Extra":"retain"}]}}}',
    );
    const before = clone(data);
    const steps = plotSteps(data, "demo");
    steps.push({
      ...clone(steps[0]),
      Id: invocationId(
        "text.join",
        steps.map((s) => s.Id),
      ),
    });
    const result = setPlotSteps(data, data, "demo", steps);
    expect(result.extension).toEqual(before.extension);
    expect((result.Plots as JsonObject).demo).toMatchObject({
      Unknown: { kept: true },
      Steps: [
        { Id: "first", Extra: "retain" },
        { Id: "text_join_1", Extra: "retain" },
      ],
    });
    expect(data).toEqual(before);
    const removed = removeOverride(data, "/extension/nil");
    expect((removed.extension as JsonObject).nil).toBeUndefined();
    expect(data.extension).toMatchObject({
      nil: null,
      enabled: false,
      count: 0,
      items: [],
    });
  });

  it("overrides inherited steps without flattening inherited plot metadata", () => {
    const layer = { Unknown: { opaque: [false, null, 0] } };
    const effective = {
      Plots: {
        demo: {
          Defaults: { Separator: "-" },
          VendorExtension: true,
          Steps: [
            "text.join:Section",
            { Step: "text.join", With: { Items: ["two"] } },
          ],
        },
      },
    };
    const steps = plotSteps(effective, "demo");
    expect(steps.map((s) => s.Id)).toEqual(["step1", "step2"]);
    const reordered = moveStep(steps, 1, -1);
    expect(reordered.map((s) => s.Id)).toEqual(["step2", "step1"]);
    const result = setPlotSteps(layer, effective, "demo", reordered);
    expect((result.Plots as JsonObject).demo).toMatchObject({
      Steps: [{ Id: "step2" }, { Id: "step1", Section: "Section" }],
    });
    expect(
      Object.keys((result.Plots as JsonObject).demo as JsonObject),
    ).toEqual(["Steps"]);
    expect(result.Unknown).toEqual(layer.Unknown);
  });

  it("selects exact raw invocation arrays by engine file origin while preserving local plot-only overrides", () => {
    const raw = parseObject(
      '{"plots":{"demo":{"VendorInherited":0.123456789012345678901,"steps":[{"id":"first","step":"text.join","with":{"items":[]},"UnknownInvocation":9007199254740993}]}}}',
    );
    const selected = parseObject(
      '{"Plots":{"demo":{"Defaults":{"Separator":"-"},"UnknownLocal":0.99999999999999999}}}',
    );
    const source = plotSource(
      {
        Configuration: {
          Plots: {
            demo: {
              Steps: [{ Id: "first", Step: "text.join", With: { Items: [] } }],
            },
          },
        },
        Sources: { "Plots.demo.Steps": "/project/default.json" },
        RawLayers: [
          {
            id: "default",
            label: "Default",
            path: "default.json",
            file: "/project/default.json",
            etag: "raw",
            data: raw,
          },
        ],
      },
      "demo",
    );
    expect(source).toBe(raw);
    expect(ownsPlotSteps(selected, "demo")).toBe(false);
    const steps = plotSteps(source!, "demo");
    steps[0].With.items = ["changed"];
    const edited = setPlotSteps(selected, source!, "demo", steps);
    const serialized = stringifyJson(edited)!;
    expect(serialized).toContain('"UnknownInvocation":9007199254740993');
    expect(serialized).toContain('"UnknownLocal":0.99999999999999999');
    expect(serialized).toContain('"Defaults":{"Separator":"-"}');
    expect(serialized).not.toContain("VendorInherited");
    expect(serialized).not.toContain('"With"');
  });

  it("uses JSON pointers so dotted/slashed keys survive restoring inheritance", () => {
    const data = {
      "key.with.dots": { "a/b": { "~special": null }, preserved: false },
      array: [1, 2],
    };
    expect(removeOverride(data, "/key.with.dots/a~1b/~0special")).toEqual({
      "key.with.dots": { "a/b": {}, preserved: false },
      array: [1, 2],
    });
    expect(() => removeOverride(data, "/array/0")).toThrow(/Array values/);
    expect(() => parseObject("[]")).toThrow(/JSON object/);
  });
  it("matches native case-insensitive field lookup and retains original key spelling", () => {
    expect(invocationId("text.join", ["TEXT_JOIN_1"])).toBe("text_join_2");
    const data = parseObject(
      '{"vendor":false,"plots":{"INSTALL":{"vendorPlot":0,"steps":[{"id":"compose","step":"text.join","with":{"items":[],"separator":"-"},"vendorStep":null},{"id":"save","step":"filesystem.write","with":{"path":"hello.txt","content":{"$ref":"steps.compose.Output.Text"}}}]}}}',
    );
    const steps = plotSteps(data, "install");
    expect(steps[0].Id).toBe("compose");
    expect(member(steps[0].With, "Items")).toEqual([]);
    setMember(steps[0].With, "Separator", "");
    const result = setPlotSteps(data, data, "INSTALL", moveStep(steps, 1, -1));
    expect(Object.keys(result)).toEqual(["vendor", "plots"]);
    expect((result.plots as JsonObject).INSTALL).toMatchObject({
      vendorPlot: 0,
      steps: [
        { id: "save", step: "filesystem.write" },
        {
          id: "compose",
          step: "text.join",
          with: { items: [], separator: "" },
          vendorStep: null,
        },
      ],
    });
    expect(JSON.stringify(result)).not.toContain('"With"');
    expect(JSON.stringify(result)).not.toContain('"Steps"');
  });
});

describe("saved wizard settings", () => {
  it("keeps exact answer keys while resolving case-insensitive settings and preserving explicit values", () => {
    const wizard: Wizard = { title: "Example", description: "", plot: "install", groups: [{ id: "settings", title: "Settings", fields: [
      { key: "target", label: "First", type: "string", settingPath: "values.first", default: "fallback" },
      { key: "Target", label: "Second", type: "string", settingPath: "Values.Second", default: "fallback" },
      { key: "__proto__", label: "Null", type: "string", settingPath: "Values.Nil", default: "fallback" },
      { key: "enabled", label: "Enabled", type: "bool", settingPath: "Values.Enabled", default: true },
      { key: "count", label: "Count", type: "int", settingPath: "Values.Count", default: 5 },
      { key: "items", label: "Items", type: "array", settingPath: "Values.Items", default: ["fallback"] },
    ] }] };
    const result = hydrateWizard(wizard, { Values: { First: "first", Second: "second", Nil: null, Enabled: false, Count: 0, Items: [] } });
    expect(Object.keys(result.values)).toEqual(["target", "Target", "__proto__", "enabled", "count", "items"]);
    expect(result.values).toMatchObject({ target: "first", Target: "second", enabled: false, count: 0, items: [] });
    expect(result.values.__proto__).toBeNull();
    expect(Object.getPrototypeOf(result.values)).toBe(Object.prototype);
  });

  it("does not resolve or expose references from saved ancestors, nested values or defaults", () => {
    const wizard: Wizard = { title: "Example", description: "", plot: "install", groups: [{ id: "settings", title: "Settings", fields: [
      { key: "ancestor", label: "Ancestor", type: "string", settingPath: "Alias.Child", default: "fallback" },
      { key: "nested", label: "Nested", type: "array", settingPath: "Values.Items" },
      { key: "default", label: "Default", type: "string", settingPath: "Missing", default: { $env: "PRIVATE" } },
    ] }] };
    const result = hydrateWizard(wizard, { Alias: { $ref: "settings.Other" }, Values: { Items: [{ $env: "PRIVATE" }] } });
    expect(result).toEqual({ values: {}, referenced: ["ancestor", "nested", "default"] });
  });

  it("preserves a target-layer reference even when an environment shadows it with a literal", () => {
    const wizard: Wizard = { title: "Example", description: "", plot: "install", groups: [{ id: "settings", title: "Settings", fields: [
      { key: "message", label: "Message", type: "string", settingPath: "Sample.Message" },
    ] }] };
    expect(hydrateWizard(wizard, { Sample: { Message: "environment literal" } }, { Sample: { Message: { $env: "PRIVATE" } } })).toEqual({ values: {}, referenced: ["message"] });
  });
});
