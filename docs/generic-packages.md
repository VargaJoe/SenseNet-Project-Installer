# General-purpose packages

These native packages work with explicit inputs and structured outputs. They use PowerShell/.NET and local files; no administrator privileges, external command-line tools, global legacy settings or application-specific resources are required. Each package directory is independently installable.

## Filesystem

| Step | Inputs | Output |
| --- | --- | --- |
| filesystem.write | Path, Content (default empty), Overwrite (default false) | Path, Bytes |
| filesystem.copy | Source file, Destination file, Overwrite (default false) | Path, Bytes |
| filesystem.read | Path (UTF-8 text) | Path, Content |
| filesystem.mkdir | Path | Path, Created |
| filesystem.copy-tree | Source directory, Destination directory, Overwrite (default false) | Path, Files |
| filesystem.remove | Path, Root, Recurse (default false), MissingOk (default false) | Path, Removed |
| filesystem.hash | Path | Path, Algorithm (SHA256), Hash (lowercase hex) |

Paths are literal, not wildcard expressions. Relative paths resolve against WorkDirectory. File writes/copies require an existing parent directory; use mkdir to create it.

copy-tree copies the **contents** of Source, including hidden files and empty directories. It merges into an existing destination without deleting unrelated files. Source and destination cannot overlap and must be below the filesystem root. All known destination conflicts are checked before copying the first file. Links/junctions are rejected for tree operations. This is a content copy, not a backup of ACLs, alternate streams or filesystem metadata.

remove requires an explicit Root. Path must be strictly inside that root; Root itself and paths escaping it are rejected. Nonempty directories require Recurse. MissingOk returns Removed=false for an absent target. Link/junction traversal is rejected. Use a specific workspace/output directory as Root.

## ZIP archives

| Step | Inputs | Output |
| --- | --- | --- |
| archive.pack | Source directory, Destination ZIP file, Overwrite (default false) | Path, Files, Bytes |
| archive.unpack | Source ZIP file, Destination directory, Overwrite (default false) | Path, Files |

pack includes directory contents, hidden files and empty directories. The ZIP must be outside Source and its parent must exist. It writes a temporary file beside the destination, then publishes the completed archive. Existing ZIP files require explicit Overwrite.

unpack creates the destination directory. It checks entries and destination conflicts before writing: traversal/absolute paths, links, duplicate targets and file-vs-directory conflicts are rejected. Existing files require Overwrite; unrelated destination files remain. This is ZIP support, not a general 7-Zip-format wrapper.

Copy/extraction can leave partial output on an I/O failure after validation. These operations are not transactional directory deployments. They operate on trusted local filesystem state; they are not an isolation boundary against concurrent filesystem changes.

## JSON

| Step | Inputs | Output |
| --- | --- | --- |
| json.read | Path | Path, Value |
| json.write | Path, Value (object), Overwrite (default false) | Path, Bytes |
| json.merge | Paths (nonempty ordered array of file paths) | Paths, Value |

The JSON root must be an object. Keys use PowerShell's case-insensitive map semantics. merge reads files in order: objects merge recursively, arrays replace completely, and explicit null/false/zero remain values. It does not change input files or interpret Plot Manager directives inside those files.

Use the merge output as the Value of json.write to save it. write uses UTF-8 without BOM and serializes before changing the destination; its parent must already exist. Existing files require Overwrite. Writes use a temporary file beside the destination and replace it only after serialization succeeds.

The engine's configuration layers and json.merge are separate: configuration layers define the run; json.merge processes arbitrary object-shaped JSON documents during a run.

## XML

xml.set takes Source, Destination, XPath, Value, optional Namespaces (prefix-to-URI map), and Overwrite (default false). It returns Path and Updated=1.

XPath must select exactly one attribute or leaf element. Values are assigned through the XML API, so XML characters are escaped correctly. For default XML namespaces, give the namespace a prefix in Namespaces and use that prefix in XPath. DTDs/external entities are rejected. The destination's parent must exist. Updating Source in place requires Destination=Source and Overwrite=true.

This updates an existing node; it does not create a schema, invent missing nodes, or perform text replacement across an XML document. Output is UTF-8; semantic content/whitespace is retained where possible, not byte-identical formatting.

## Preview and composition

Native runner WhatIf skips all step functions. Every mutating function also implements ShouldProcess for direct WhatIf calls. Output references refer to completed earlier invocations; a failed step stops the remaining plot. No automatic rollback or finally/cleanup phase is provided.

The packages do not log document contents. Outputs from read/merge intentionally contain data, which the CLI serializes; keep secrets out of displayed results.

## Complete local example

The example combines three configuration files, generates JSON/XML, stages a directory, creates and restores a ZIP, reports two hashes, and removes only the staging directory.

From the repository root, use a **fresh** output directory:

~~~powershell
$example = './src/Deployment/Scripts/Examples/layered-artifact'
$work = Join-Path ([IO.Path]::GetTempPath()) ('plot-example-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $work
./src/Deployment/Scripts/Run.ps1 layered-artifact -DefaultConfigPath "$example/default.json" -ConfigPath "$example/project.json" -EnvironmentConfigPath "$example/environment.json" -WorkDirectory $work
~~~

Expected: Succeeded; restored/report.json has Label=Example project, Environment=preview, Enabled=false, Iterations=0 and Formatting.Keep=inherited. originalHash and restoredHash outputs match. Output contains bundle-input/, restored/ and bundle.zip; staging/ is removed on success.

Add -Explain to inspect the layer file order and parameter sources, or -WhatIf to skip operations. To clean up the generated directory, use filesystem.remove with Path=$work, Root=[IO.Path]::GetTempPath() and Recurse=true, after inspecting the path. Re-running in the same output directory fails on existing output files.

## Migration status

This first batch implements reusable file/directory, ZIP and JSON/XML operations as native packages. These are new general contracts, not aliases for historical deployment functions. Legacy scripts remain available only through legacy mode.

The next generic group is now included: [process, HTTP/TCP, Git, build/NuGet and Docker](operations-packages.md). [SQL Server, IIS provisioning, web maintenance and Compose](platform-packages.md) are also available as native steps, with a [local GUI/integration contract](local-integration.md). Application-specific installers, charts, environment settings and data remain outside this work.
