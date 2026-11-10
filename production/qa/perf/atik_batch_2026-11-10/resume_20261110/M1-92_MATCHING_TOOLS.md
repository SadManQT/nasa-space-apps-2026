# M1-92 — matching native profiling recheck

10 November 2026, Atik/codex. Status: matching-tool/symbol prerequisite unavailable;
no native cause, candidate fix or controlled before/after result is claimed.

## Exact local evidence

- Installed executable: `/tmp/last-light-tools/Godot.app/Contents/MacOS/Godot`.
- `--version`: `4.7.2.stable.official.ed1daf0bf`.
- `dwarfdump --uuid`: arm64 **5EF81F68-A5CB-3B0C-82FF-E288702E954D**;
  x86_64 **9ED63934-491E-3C34-9862-618A9C738B79**.
- `xcode-select -p`: `/Library/Developer/CommandLineTools`.
- `xcrun --find xctrace`: utility unavailable; full Xcode.app is not present.
- Targeted local symbol lookup (tools directory plus indexed dSYM UUID query)
  found no matching supplied dSYM. This is not a claim about unindexed/private
  artifacts elsewhere.
- `atos` against this exact arm64 executable/load address still returns unnamed
  numeric code offsets for the old sample's native wait frames. Those offsets
  do not identify a source-level cause.

The [official expanded4.7.2 release asset list](https://github.com/godotengine/godot-builds/releases/expanded_assets/4.7.2-stable)
was also checked. It lists Android native-symbol archives but no separately named
macOS native-symbol package. No Android/other-version symbols were substituted.
A web API failure was not treated as proof of package absence; the expanded
release listing was read instead.

## What the previous sample does and does not show

The retained sample was captured during the **title**, before the later campaign
entry. It is unsymbolicated and does not locate the6.61s campaign frame. A native
condition-variable wait and a compiler queue appearing in that sample are not
proof of a campaign shader/GPU/threaded-loading cause. The sample and both prior
native attempts remain unchanged.

## Resume with matching data

Provide matching arm64 symbols (UUID above) or a native profiling setup that can
attribute the actual running build. Capture against explicit first-campaign/first
room-draw markers, not an assumed wall delay after title launch. Keep executable,
hardware, renderer/driver, resolution, quality, cache policy, source, isolated saves
and first-use work accounted for in both baseline and candidate captures.

Only after a measured cause is isolated should an owned candidate be changed.
Then run controlled before/after captures with full frame CSV/JSON/logs and loading
screenshots, retain unsuccessful attempts, obtain review and run required tests.
No new native probe was run concurrently with the integrated full collection;
headless timing passes cannot certify this native first-draw requirement.
