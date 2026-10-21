import {
  isLosslessNumber,
  isSafeNumber,
  LosslessNumber,
  parse,
  stringify,
} from "lossless-json";

// API counters and ordinary schema values stay native numbers. Values outside
// Number's exact range remain numeric scalars, retaining their original token.
// In particular, never turn an overflow/underflow into Infinity, null, or zero.
function exactNumber(token: string): number | LosslessNumber {
  const value = Number(token);
  return isSafeNumber(token) && !Object.is(value, -0)
    ? value
    : new LosslessNumber(token);
}

export function parseJson<T = unknown>(text: string): T {
  return parse(text, undefined, { parseNumber: exactNumber }) as T;
}

export function stringifyJson(
  value: unknown,
  space?: number,
): string | undefined {
  return stringify(
    value,
    (_key, item) => {
      if (typeof item === "number" && !Number.isFinite(item)) {
        throw new Error(
          "A non-finite JavaScript value cannot be saved as JSON. Enter the exact numeric JSON literal instead.",
        );
      }
      return item;
    },
    space,
  );
}

export function numberInput(text: string): number | LosslessNumber {
  const value = parseJson(text);
  if (typeof value !== "number" && !isLosslessNumber(value)) {
    throw new Error("Enter a JSON number.");
  }
  return value;
}

export { isLosslessNumber, type LosslessNumber };
