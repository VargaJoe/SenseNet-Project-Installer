import { describe, expect, it } from "vitest";
import { isLosslessNumber, parseJson, stringifyJson } from "./json";
import { object } from "./model";

describe("exact JSON numeric boundaries", () => {
  it("keeps normal API counters native and unsafe JSON numbers numeric scalars", () => {
    const values = parseJson<unknown[]>('[0,1,2.3,9007199254740991,9007199254740993,0.99999999999999999,1e400,1e-400]');
    expect(values.slice(0, 4)).toEqual([0, 1, 2.3, Number.MAX_SAFE_INTEGER]);
    expect(values.slice(4).every(isLosslessNumber)).toBe(true);
    expect(values.slice(4).some(object)).toBe(false);
    expect(stringifyJson(values)).toBe('[0,1,2.3,9007199254740991,9007199254740993,0.99999999999999999,1e400,1e-400]');
  });
  it("does not confuse ordinary unknown objects with the legacy wrapper marker", () => {
    const value = parseJson('{"isLosslessNumber":true,"value":"123","unknown":false}');
    expect(object(value)).toBe(true);
    expect(isLosslessNumber(value)).toBe(false);
    expect(stringifyJson(value)).toBe('{"isLosslessNumber":true,"value":"123","unknown":false}');
  });
  it("rejects already-nonfinite JavaScript numbers instead of saving them as null", () => {
    expect(() => stringifyJson({ value: Infinity })).toThrow(/non-finite/);
    expect(() => stringifyJson({ value: NaN })).toThrow(/non-finite/);
  });
});
