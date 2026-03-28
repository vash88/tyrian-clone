# Repository Working Rules

## Git Conventions

- Use Conventional Commit style prefixes for commits.
- `feat:` for new user-facing functionality
- `fix:` for bug fixes
- `docs:` for documentation-only changes
- `refactor:` for internal code restructuring without behavior change
- `test:` for tests and test-only infrastructure
- `chore:` for maintenance work that is not user-facing
- `perf:` for performance improvements
- `build:` for build system or dependency packaging changes
- `ci:` for CI workflow changes
- `revert:` for explicit reversions

## Branching Rules

- Never create a branch unless the user explicitly asks for one.
- Never switch branches unless the user explicitly asks for it.
- Default to working on the current branch in place.

## Commit Behavior

- Do not make a commit unless the user explicitly asks for one.
- Keep commit messages concise and scoped to the actual change set.
- Avoid mixing unrelated changes into the same commit when it is practical to separate them.
