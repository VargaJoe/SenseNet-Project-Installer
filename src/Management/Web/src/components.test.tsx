import { fireEvent, render, screen, cleanup } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { ParameterField } from "./components";
import { parseObject } from "./model";
import { stringifyJson } from "./json";

afterEach(cleanup);
describe("schema-driven parameters", () => {
  it("edits an unsafe numeric scalar as exact JSON instead of exposing wrapper fields or rounding", () => {
    const change = vi.fn();
    const value = parseObject('{"precise":9007199254740993}').precise;
    render(
      <ParameterField
        name="Precise"
        schema={{ Type: "int" }}
        value={value}
        onChange={change}
      />,
    );
    const editor = screen.getByLabelText("Precise JSON value");
    expect(editor).toHaveValue("9007199254740993");
    fireEvent.change(editor, { target: { value: "9007199254740995" } });
    fireEvent.blur(editor);
    expect(stringifyJson(change.mock.calls[0][0])).toBe("9007199254740995");
  });
  it("makes inherited values, explicit null and false separate choices", () => {
    const change = vi.fn();
    const { rerender } = render(
      <ParameterField
        name="Enabled"
        schema={{ Type: "bool", AllowNull: true }}
        value={undefined}
        onChange={change}
      />,
    );
    fireEvent.change(screen.getByLabelText("Enabled value source"), {
      target: { value: "value" },
    });
    expect(change).toHaveBeenLastCalledWith(false);
    rerender(
      <ParameterField
        name="Enabled"
        schema={{ Type: "bool", AllowNull: true }}
        value={false}
        onChange={change}
      />,
    );
    expect(screen.getByLabelText("Enabled")).toHaveValue("false");
    fireEvent.change(screen.getByLabelText("Enabled value source"), {
      target: { value: "null" },
    });
    expect(change).toHaveBeenLastCalledWith(null);
    fireEvent.change(screen.getByLabelText("Enabled value source"), {
      target: { value: "inherit" },
    });
    expect(change).toHaveBeenLastCalledWith(undefined);
  });
  it("does not replace numeric zero or an explicit empty array with defaults", () => {
    const change = vi.fn();
    const { rerender } = render(
      <ParameterField
        name="Count"
        schema={{ Type: "int", Default: 5 }}
        value={0}
        onChange={change}
      />,
    );
    expect(screen.getByLabelText("Count")).toHaveValue(0);
    rerender(
      <ParameterField
        name="Items"
        schema={{ Type: "array", Default: ["default"] }}
        value={[]}
        onChange={change}
      />,
    );
    expect(screen.getByLabelText("Items JSON value")).toHaveValue("[]");
    fireEvent.change(screen.getByLabelText("Items JSON value"), {
      target: { value: "[invalid" },
    });
    fireEvent.blur(screen.getByLabelText("Items JSON value"));
    expect(screen.getByRole("alert")).toHaveTextContent("Invalid JSON");
    expect(change).not.toHaveBeenCalled();
  });
  it("shows declared values and produces native references without interpreting them", () => {
    const change = vi.fn();
    render(
      <ParameterField
        name="Mode"
        schema={{
          Type: "string",
          ValidateSet: ["safe", "fast"],
          Description: "Choose a build mode.",
        }}
        value="safe"
        references={["steps.first.Output.Text"]}
        onChange={change}
      />,
    );
    expect(screen.getByText("Choose a build mode.")).toBeVisible();
    fireEvent.change(screen.getByLabelText("Mode"), {
      target: { value: '"fast"' },
    });
    expect(change).toHaveBeenLastCalledWith("fast");
    fireEvent.change(screen.getByLabelText("Mode value source"), {
      target: { value: "reference" },
    });
    expect(change).toHaveBeenLastCalledWith({
      $ref: "steps.first.Output.Text",
    });
  });
  it("never renders a schema-declared literal secret in the input DOM", () => {
    const { container } = render(
      <ParameterField
        name="Password"
        schema={{ Type: "string", Secret: true }}
        value="must-never-render"
        onChange={() => {}}
      />,
    );
    expect(container.innerHTML).not.toContain("must-never-render");
    expect(screen.getByText(/Literal hidden/)).toBeVisible();
  });
});
