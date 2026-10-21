import { describe, expect, it } from "vitest";
import {
  clone,
  invocationId,
  member,
  moveStep,
  parseObject,
  plotSteps,
  removeOverride,
  setMember,
  setPlotSteps,
  type JsonObject,
} from "./model";

describe("source-layer editing without configuration resolution", () => {
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

  it("preserves inherited plot metadata when explicitly overriding its steps", () => {
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
      Defaults: { Separator: "-" },
      VendorExtension: true,
      Steps: [{ Id: "step2" }, { Id: "step1", Section: "Section" }],
    });
    expect(result.Unknown).toEqual(layer.Unknown);
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
