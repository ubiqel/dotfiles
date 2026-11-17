# Custom Rules for Brainstorm

Custom rules let you inject project-specific or personal conventions into the brainstorm workflow. Rules are free-form markdown loaded at skill invocation time and applied as additional instructions alongside the skill's built-in behavior.

## File Locations

Two levels, checked in order (first-found-wins, never merged):

1. **Project-level**: `.opencode/brainstorm-rules.md` in the current working directory
2. **User-level**: `~/.config/opencode/brainstorm-rules.md`

When both non-empty files exist, only the project-level file is used. Empty files are treated as absent and fall through to the next level.

## Resolution

The skill runs `~/.config/opencode/scripts/resolve-rules.sh brainstorm-rules.md ~/.config/opencode` at startup. The script checks the project file first, then the user file, and outputs the first non-empty one. It outputs nothing if neither exists.

## Managing Rules

Ask the brainstorm skill to manage rules:

- **show rules** — displays current rules and which level they came from
- **add/update project rules** — writes to `.opencode/brainstorm-rules.md`
- **add/update user rules** — writes to `~/.config/opencode/brainstorm-rules.md`
- **clear project rules** — deletes `.opencode/brainstorm-rules.md`
- **clear user rules** — deletes `~/.config/opencode/brainstorm-rules.md`

## Example Content

```markdown
## design preferences
- prefer simple solutions over clever abstractions
- always consider backward compatibility
- propose at most 3 approaches

## technology constraints
- backend must be Go with standard library where possible
- frontend uses HTMX, avoid JavaScript frameworks
- database is SQLite via sqlx

## naming conventions
- use camelCase for variables
- use PascalCase for exported types
```

## How Rules Apply

Rules influence design preferences, naming conventions, technology choices, and other aspects of the brainstorm dialogue. They supplement built-in instructions — they never replace them.
