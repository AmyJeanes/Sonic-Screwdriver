# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Garry's Mod (Lua) addon shipping the `swep_sonicsd` SWEP — a Sonic Screwdriver tool from Doctor Who. The weapon traces forward, classifies whatever it hits by entity class or `data.ent.*` field, and dispatches to one of many *function* modules (`SWEP:AddFunction`) that interact with that thing: doors, buttons, NPCs, vehicles, props, Wire keypads, TARDIS exteriors, etc.

Loaded in-place at `garrysmod/addons/Sonic-Screwdriver/`. No `addon.json` workflow, no CI, no build step.

There is also a `SonicSD.*` namespace defined in `lua/autorun/sonicsd.lua` that loads supporting files from `lua/sonicsd/`. The `SonicSD:AddSonic` table-driven registry decides which sonic models, sounds, lights and animations are available; each entry becomes a separate `Weapon` list entry (`sonicsd-<id>`) and shows up in the Spawnmenu under "Doctor Who - Sonic Tools".

## Architecture

### Two-loader layout

There are two loaders, both with the same shape:

- `lua/autorun/sonicsd.lua` defines `SonicSD:LoadFolder(folder, addonly, noprefix)`. It scans `lua/sonicsd/<folder>/*.lua` (or just `lua/sonicsd/*.lua` when called with no folder) and dispatches by realm-prefix (`sh_`, `sv_`, `cl_`). A `noprefix` flag skips the realm filter (used for the vendored vON library and the sonic definitions). It is called three times: `libraries/libraries`, `libraries`, then the root.
- `lua/weapons/swep_sonicsd/shared.lua` defines `SWEP:LoadFolder(folder, addonly, noprefix)` with the *same* logic, scanning `lua/weapons/swep_sonicsd/<folder>/*.lua`. It is called once with `"modules"` to autoload every module file.

Both loaders rely on the realm-prefix in the *filename*. The static analyzer (`glua_ls`) recognizes the same convention. Suffix conventions (`x_sh.lua`) would break the analyzer's realm-awareness heuristic — keep the prefix style.

### `SonicSD.sonics` registry (`lua/sonicsd/sh_sonics.lua`)

Each `SonicSD:AddSonic({ ID = ..., Base = ..., ... })` entry is merged onto its base (default base is the `base` entry) and registered as a separate weapon spawn list entry. The Spawnmenu icon, default colors, sound loops, animations, and view/world models all come from this table. The `IsBase = true` flag prevents the entry from appearing in the spawn list (the `base` entry itself is just a template).

`SonicSD_OVERRIDES` is a third-party hook for downstream addons to override `MainCategory` (and would be the right place to add other overrides — but it is currently the only key). Favorites are persisted to `data/sonicsd_favorites.txt` via the vendored vON serializer.

### The SWEP

`lua/weapons/swep_sonicsd/`:

- `shared.lua` — the SWEP class itself. Defines `Get/SetSonicID`, `Get/SetSonicMode`, the function-pipeline registration (`AddFunction`), and the per-instance `hooks` system (`AddHook`/`RemoveHook`/`CallHook`) which is *separate from* GMod's global `hook.*` library. The SWEP uses both: `hook.Call(...)` for engine hooks (`PlayerUse`, `PhysgunPickup`, `CanTool`), and `self:CallHook(...)` for module-internal events (`Initialize`, `SonicChanged`, `ModeChanged`, `Reload`, `Holster`, `OnRemove`, `Hold`, `Think`, `PreDrawViewModel`, `CanUse`/`CanMove`/`CanTool`).
- `init.lua` (server) — `Think` runs the trace-and-wait loop: hold mouse1 or mouse2 for `WaitTime` seconds with the crosshair on a target, then call `:Go(ent, trace, keydown1, keydown2)` which builds `self.data` and runs every registered `function` against it. Reload (held) toggles mode, tap fires the `Reload` hook.
- `cl_init.lua` — handles the viewmodel draw, weapon-select icon, holster sound, and forwards client-side keypress state to the `Think` and `PreDrawViewModel` hooks.

### Function modules (`modules/`)

Each module file calls `SWEP:AddFunction(function(self, data) ... end)`. `data` is `{class, ent, hooks={canuse, canmove, cantool}, keydown1, keydown2, trace}`. Functions check `data.class` (string from `ent:GetClass()`) and the relevant `hooks.*` permission flag, then act. Order matters only in that early-returners can short-circuit (most don't — they just no-op when the class doesn't match).

Notable cross-cuts:

- **TARDIS integration (`sh_doctorwho.lua`)** — distinguishes legacy (no `TardisExterior` field) from new TARDIS by `IsLegacy(ent) == not ent.TardisExterior`. Legacy uses methods like `:Go`, `:LongReappear`, `:ToggleLocked`, `:TogglePhase`, accessed through `data.ent` (untyped). New TARDIS uses `:Demat`, `:ToggleLocked(callback, true)`, and the `TARDIS:Message`/`TARDIS:ErrorMessage` chat globals. Both branches are guarded; `TARDIS` may be nil if neither addon is installed (in which case nothing in the Doctor Who module activates).
- **WireMod (`sv_wiremod.lua`)** — guarded by `if WireLib then`. Talks to `gmod_wire_keypad` and `wired_door`. Optional: the addon works fine without WireMod loaded.
- **Doors (`sv_doors.lua`)** — operates on engine `func_door` / `func_door_rotating` / `prop_door_rotating`. *Not* the AmyJeanes/Doors addon — those are handled via the TARDIS exterior code path (`data.ent.TardisExterior`).

### Material proxies (`lua/matproxy/sonicsd_color.lua`)

`SonicSDColor` and friends are bound on the sonic's worldmodel and viewmodel materials. They read `sonic_light_*` / `sonic_light2_*` / `sonic_lightoff_*` ConVars per-frame and feed the resulting RGB vector into `mat:SetVector(self.ResultTo, ...)`. The "active" pulse and color-switching logic checks `IN_ATTACK`/`IN_ATTACK2` directly on the weapon's owner. There is no SWEP-side coordination — these proxies live entirely in the material system.

### Vendored vON (`lua/sonicsd/libraries/sh_von.lua`)

Third-party serializer (Vercas, MIT-ish license header in the file). Used only for persisting the favorites file. **Do not edit this file**; the analyzer is silenced via a file-level `---@diagnostic disable` (no categories — disables all) at the top, matching the pattern used in `Doors` and `TARDIS` for the same vendored library. Prefer the inline disable over excluding the file via `ignoreGlobs` so the file is still parsed (syntax errors and parse failures still surface) — only diagnostics are suppressed.

## Conventions when adding code

- **Realm-prefix filenames.** `sh_`, `sv_`, `cl_` as prefixes in the modules folder so the loader and the static analyzer dispatch correctly.
- **Use `self:GetOwner()` not `self.Owner`** in SWEP code. The `SWEP.Owner` field is deprecated in the GLua API stubs, and `:GetOwner()` is the supported form on `Weapon`. Cache it in a `local owner` at the top of methods that use it many times rather than peppering `self:GetOwner()` everywhere.
- **Function modules return-or-fall-through.** Each `AddFunction` runs unconditionally — there's no class-based dispatch. If your module has nothing to do, return early; don't rely on ordering to skip work. The trace data is shared (`self.data`) across the whole pipeline, so don't mutate it.
- **Hooks fire from `self:CallHook`, not `hook.Call`.** Module-internal events (`Initialize`, `SonicChanged`, `ModeChanged`, ...) use the per-SWEP hooks dispatcher and propagate first-non-nil returns. Don't conflate these with global GMod hooks.

## Tooling

`.luarc.json` configures `glua_ls` / `glua_check` (both on EmmyLua-Analyzer-Rust) with `./.tools/glua-api` (GLua type stubs) plus sibling addons (`../TARDIS`, `../TARDIS-Legacy`, `../wire`) as workspace libraries. The recommended VS Code extension is `Pollux.gmod-glua-ls`.

`ignoreGlobs` excludes `.tools/*.zip` (the API-stubs download archive).

### Optional dependencies via sibling addons

The Doctor Who module (`sh_doctorwho.lua`) calls `TARDIS:Message`/`:ErrorMessage` and `ent:Demat` (new TARDIS) plus `:Go`/`:LongReappear`/`:ToggleLocked`/`:TogglePhase` (legacy TARDIS). The Wiremod module (`sv_wiremod.lua`) calls `Wire_TriggerOutput`. All runtime call sites are guarded (`if WireLib and ...`, `data.ent.TardisExterior`, `IsLegacy(ent)`) so the addon works without any of those installed.

For static analysis, `.luarc.json` references the *real* sibling addons rather than carrying hand-written stubs:

- `../TARDIS` — provides `TARDIS:Message`/`:ErrorMessage` (`tardis/libraries/libraries/sh_notifications.lua`) and `ENT:Demat` (`entities/gmod_tardis/modules/teleport/sh_tp_main.lua`).
- `../TARDIS-Legacy` — provides the legacy exterior methods (`:Go`, `:LongReappear`, etc.).
- `../wire` — provides `WireLib.TriggerOutput` and the `Wire_TriggerOutput` alias.

Workspace.library entries are *analysis sources*, not *diagnostic targets* — TARDIS's own warnings don't bleed into Sonic-Screwdriver's output. If a contributor clones Sonic-Screwdriver without those siblings present, glua_ls warns about missing library paths and the optional-call sites go back to `undefined-global` / `undefined-field`, but the rest of the analysis is unaffected. This is the same pattern TARDIS itself uses (`../Doors`, `../world-portals`, `../Sonic-Screwdriver`, `../wire` in its own `.luarc.json`).

`.luarc.json` runs with **every diagnostic rule enabled** — there is no project-wide `diagnostics.disable` block. glua_ls 1.0.20+'s `need-check-nil` / `unchecked-nil-access` / `undefined-field` were briefly disabled wholesale when they first shipped, but the warnings they raised turned out to be either real or fixable with one annotation:

- **`undefined-field`** — `self.anims` is built with dynamic string keys, so named access (`.mode`) looked undefined. Fixed by the `SonicSDAnim` class plus `---@type table<string, SonicSDAnim>` on the field (`cl_animation.lua`).
- **`unchecked-nil-access`** — flagged redundant `self:GetOwner().linked_tardis` re-reads (the validated local `tardis` should be used instead) and an unguarded `e.interior:GetSecurity()` deref (`sh_doctorwho.lua`). Fixed by using the validated locals and an `IsValid` guard.
- **`need-check-nil`** — `SWEP:GetSonic()` inferred a nilable return; annotated `---@return table` since it always falls back to the `default` entry. A client-side owner re-read was cached into a local.

The one subtle case is `sv_wiremod.lua`: `IsValid()` narrows the untyped `data.ent` to a bare `Entity`, which the stubs don't know carries the keypad's `SetDisplayText` / `CurrentNum` — those are built at runtime (a `NetworkVar` accessor and a plain field write) with no static definition. Rather than disable the rule, `.luatypes/wire.lua` declares `---@class gmod_wire_keypad : Entity` (only the members we use) and `sv_wiremod.lua` casts `data.ent` to it; `IsValid()` preserves the cast type, so the members resolve. `.luatypes/` is the home for external/engine type shapes the glua-api stubs miss (it already overrides `table.insert` and `Panel:Add` in `glua_overrides.lua`) — distinct from project-specific *globals*, which stay inline at their use site. Prefer code-level fixes or targeted annotations over a blanket disable.

### Type annotations

Patterns that matter for this codebase:

- **`self.Owner` vs `self:GetOwner()`**. The stub marks `SWEP.Owner` `@deprecated`. Replacing field accesses with the method call is the supported fix; `self:GetOwner()` returns a `Player` (or `Entity?` if unequipped). When using it for many subsequent calls, capture once: `local owner = self:GetOwner()`.
- **Trace filter shape (`{ self:GetOwner() }`)**. `util.QuickTrace`'s third arg is `Entity | Entity[]`. An inline `{ owner }` literal occasionally fails to unify with `Entity[]` because the analyzer narrows the element type and won't widen back. Pass the `owner` Entity directly when the filter is a single entity.
- **Project-specific globals** (e.g. `DEBUG_SONICSD_SPAWNMENU_CATEGORY_OVERRIDE`, used once at the top of `swep_sonicsd/shared.lua` as a debug knob). Annotate them with `---@diagnostic disable-next-line: undefined-global` directly above the use site rather than carrying a `.luatypes/` stub — they belong with the code that reads them, not in a glua-api override layer.

<!-- >>> GENERATED shared conventions (gmod-addon-tools) - do not edit; regen: scripts/generate-claude-md.ps1 >>> -->

_Shared conventions for my GMod addons - generated from [`gmod-addon-tools/docs/gmod-addon-conventions.md`](https://github.com/AmyJeanes/gmod-addon-tools/blob/main/docs/gmod-addon-conventions.md). Edit it there, not in this file; the block below is overwritten by CI. Addon-specific guidance lives outside the markers._

## Code style

- **Pure Lua syntax only - no GMod-Lua extensions.** No `//` comments, no `continue`, no `!=`, no `&&`/`||`. Use `--`, `goto continue`, `~=`, `and`/`or`.
- **Comments: concise, the _why_ not the _what_.** A couple of lines at most; reserve length for genuinely non-obvious rationale and bias toward cutting - match the surrounding density, don't pad to essay length. Don't restate the code, don't explain it by what it replaced, and keep the _why_ self-contained (no pointers to external docs or fragile cross-file references). Keep comments ASCII: `->` not an arrow, a single spaced hyphen for a dash (never a double `--`, which reads as a second comment marker, nor an em-dash).
- **Drop the loop variable you don't use** rather than naming it: `for _, v in pairs(t)`, `for k in pairs(t)`, `for _ = 1, n do`. The `unused` lint is on - keep the noise floor at zero.
- **Every `---@diagnostic disable` needs a paired reason** on the same or preceding line naming _why_ the rule is suppressed. The default is to fix the issue, not suppress it.

## First-time setup (before touching `.lua` files)

The tooling (`glua_check`, `glua_ls`, the GLua API stubs, and the wiki/typing type-model) is provisioned by the shared [`gmod-addon-tools`](https://github.com/AmyJeanes/gmod-addon-tools) module, cloned **beside this addon**. `scripts/install-tools.ps1` is a thin wrapper - `scripts/bootstrap.ps1` resolves the sibling module and it calls `Initialize-GmodTools`, so the version pins live once in the module and every addon runs the exact same engine.

```bash
git clone https://github.com/AmyJeanes/gmod-addon-tools ../gmod-addon-tools
pwsh -File scripts/install-tools.ps1
```

It is idempotent - re-running is a no-op when the pinned versions are already present, so it is also the recovery path when diagnostics look wrong. After a fresh install, run `/reload-plugins` so Claude Code re-launches the LSP against the new binary.

## Claude Code LSP integration (`glua-lsp` plugin)

Diagnostics, hover, and jump-to-definition come from the [`glua-lsp` plugin](https://github.com/AmyJeanes/gmod-claude-plugins) (marketplace `AmyJeanes/gmod-claude-plugins`), which wraps the [`glua_ls`](https://github.com/Pollux12/gmod-glua-ls) server - the same EmmyLua-Analyzer-Rust engine as `glua_check`, running long-lived. Diagnostics arrive automatically after every edit; no hook involvement. `.claude/settings.json` declares the marketplace so contributors get prompted to install on first open, and the plugin auto-resolves `glua_ls` from this project's `.tools/bin/` at launch (no global install, no PATH plumbing). The `glua-lsp:install-glua-ls` skill covers the same recovery flow if symptoms appear later. Treat reported diagnostics as actionable only if your edit caused them - pre-existing noise on unrelated lines is not in scope for the current change.

## Whole-repo scans (`scripts/glua-check.ps1`)

`glua_ls` only analyzes files as they are opened or edited. To audit the whole repo at once, run `pwsh -File scripts/glua-check.ps1` - it provisions tooling on demand (no-op when present) and runs `glua_check --warnings-as-errors` against the workspace root. It takes no path filter, so it always scans everything; CI runs the same script. Useful after a fix ripples across the tree, or when picking the project up to surface latent issues the LSP hasn't opened yet.

## Typing enforcement (`scripts/typing-check.ps1`)

`glua_check` catches _wrong_ types but not _missing_ ones - an untyped param is a silent `any` it never flags. `Test-GmodTyping` (CI: `typing-check.yml`) closes that gap, failing the build on any of: an untyped param, annotation rot (a `---@param` for a param that no longer exists), a modeled function whose resolved return type contains `unknown`, a hook fire-site argument that resolves to `unknown`, or a `:CallHook`-style hook whose receiver resolves to `unknown` (so its "Fired on" column would render _Unknown_ - usually fixed with a `---@param self <class>` on the enclosing function). Satisfy it at the **source** - prefer a `---@param` / `---@return` / `---@class` annotation over a per-callsite `---@cast`, since annotations propagate to every caller. The only accepted escapes are explicit and greppable: `---@param x any` (a reviewed, genuine `any`), an `_` discard for a deliberately-unused arg, and a file-level `---@vendored` marker on third-party code.

Where an addon fires its own hooks, callback payload params are typed by a generated `---@overload` catalogue (`scripts/generate-hook-types.ps1`, CI: `generate-hook-types.yml`) - do not hand-edit it; retype a payload at its `CallHook` / `hook.Run` site instead. Custom global-hook overloads are spliced into the provisioned `hook.lua` by `Initialize-GmodTools`, so after pulling a change to a generated fragment mid-session, re-run `scripts/install-tools.ps1` (it re-syncs) then `/reload-plugins` to refresh live types.

## Bumping the shared tooling

Tool versions and this conventions block are pinned to a `gmod-addon-tools` tag. Bump the version constants in `gmod-addon-tools/src/install.ps1` (or edit the shared docs); merging to the module's `main` auto-cuts a new tag, and Renovate then raises a pin-bump PR here that regenerates the affected artifacts and runs GLua Check before it merges. CI pins the module by tag (the `ref:` in each workflow); a local sibling checkout uses whatever branch it is on, so keep it on the pinned tag to mirror CI exactly.

<!-- <<< END GENERATED shared conventions <<< -->
