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
  plotSource,
  ownsPlotSteps,
  removeOverride,
  setMember,
  setPlotSteps,
  type JsonObject,
} from "./model";
import { isLosslessNumber, stringifyJson } from "./json";

describe("source-layer editing without configuration resolution", () => {
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
