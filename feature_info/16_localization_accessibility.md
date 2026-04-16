---
name: Localization & Accessibility
description: 58-locale i18n via Crowdin, RTL support, pen/tablet mode detection, keyboard shortcut help dialog, platform-aware key labels
type: project
---

# Localization & Accessibility

## Overview
The app ships with 58 locale translations managed via Crowdin. Locales below 85% translation completion are hidden from users. The i18n `t()` function supports interpolation and RTL layout switching. Pen/tablet input is auto-detected and enables a dedicated pen mode. A keyboard shortcut help dialog provides platform-aware key labels.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| i18n.ts | `packages/excalidraw/i18n.ts` | full file | `t()`, `setLanguage()`, `useI18n()` hook |
| t() function | `packages/excalidraw/i18n.ts` | 127–160 | Dot-path lookup, interpolation, fallback chain |
| setLanguage | `packages/excalidraw/i18n.ts` | 92–109 | Dynamic import of locale JSON, sets `document.dir` for RTL |
| languages array | `packages/excalidraw/i18n.ts` | 21–75 | ~56 named languages with codes and RTL flags |
| 85% completion filter | `packages/excalidraw/i18n.ts` | ~70 | Hides languages below 85% (from percentages.json) |
| percentages.json | `packages/excalidraw/locales/percentages.json` | full file | Crowdin completion percentages per locale |
| locales/ directory | `packages/excalidraw/locales/` | ~58 files | One JSON file per locale |
| crowdin.yml | `/crowdin.yml` | full file | Crowdin integration config |
| editorLangCodeAtom | `packages/excalidraw/i18n.ts` | ~line 80 | Jotai atom triggering re-render on language change |
| Pen mode detection | `packages/excalidraw/components/App.tsx` | 7598–7614 | First `pointerType === "pen"` event sets `penMode: true` |
| PenModeButton.tsx | `packages/excalidraw/components/PenModeButton.tsx` | full file | Toggle button, hidden until pen detected |
| HelpDialog.tsx | `packages/excalidraw/components/HelpDialog.tsx` | full file | Keyboard shortcut reference dialog |
| toggleShortcuts action | `packages/excalidraw/actions/actionMenu.tsx` | 10 | Shortcut `?` opens help dialog |
| getShortcutKey | `packages/excalidraw/utils.ts` | ~line 50 | Platform-aware key label (Cmd vs. Ctrl) |

## How It Works

### i18n System
`t(path, replacement?, fallback?)` (i18n.ts:127–160): dot-separated key path (e.g., `"stats.title"`), type-checked against `typeof fallbackLangData` (the English JSON — TypeScript catches missing keys at compile time). Lookup order:
1. `currentLangData[path]` (active locale)
2. `fallbackLangData[path]` (English)
3. Optional `fallback` parameter string

Supports `{{key}}` interpolation: `t("labels.welcomeScreen.defaultHint", { key: "Ctrl+K" })`.

`setLanguage(lang)` (i18n.ts:92–109): dynamically imports `./locales/${lang.code}.json`, sets `document.dir = lang.rtl ? "rtl" : "ltr"`, updates `editorLangCodeAtom`. Components using `useI18n()` re-render on language change.

### Locale Filtering
The `languages` array (i18n.ts:21–75) lists all locales. At runtime, languages with completion percentage < 85% (from `percentages.json`) are filtered out. In development, two synthetic test locales (`__test__` and `__test__.rtl`) are prepended. ~56 named languages are available to users.

### Pen/Tablet Mode
**Detection** (App.tsx:7598–7607): On the first `pointerdown` event where `event.pointerType === "pen"`, `penMode: true` and `penDetected: true` are set to appState. This is a one-shot detection — once detected, it does not reset. The `PenModeButton` is hidden (`returns null`) until `penDetected` is true, then becomes a visible toggle button.

**isTouchScreen** (App.tsx:7609–7614): Separately, `["pen", "touch"]` pointer types set `editorInterface.isTouchScreen: true`. Touch mode enables: larger tap targets, disables some hover-only interactions, adjusts zoom gestures.

**What pen mode does:** Disables accidental touch scrolling (finger scrolling on tablet without intent to scroll), so users can draw with the pen while resting their palm without unwanted panning.

### Keyboard Shortcut Help Dialog
`toggleShortcuts` action (actionMenu.tsx:10): shortcut `?`. Toggles `appState.openDialog?.name === "help"`. `HelpDialog.tsx` renders sections of shortcuts using `getShortcutFromShortcutName()` and `getShortcutKey()`. `getShortcutKey()` detects the OS (Mac vs. other) and returns `"⌘"` or `"Ctrl"` accordingly — all shortcuts in the dialog show platform-correct labels. The dialog also links to documentation, blog, GitHub, and YouTube.

## Dependencies
- `document.dir` (RTL layout)
- Crowdin for translation management (`crowdin.yml`)
- `percentages.json` (dynamically maintained by Crowdin CI)
- `editorLangCodeAtom` (Jotai atom for language-aware re-renders)
- `appState.openDialog` (help dialog control)

## Pros
- **85% completion filter:** Users only see languages that are meaningfully translated — no half-translated UIs.
- **RTL is built-in:** `setLanguage()` sets `document.dir` — RTL support is structural, not bolted on.
- **Type-safe i18n keys:** `t()` is type-checked against the English JSON — missing or misspelled translation keys are compile-time errors.
- **Dynamic locale loading:** Each locale JSON is loaded on demand — no upfront bundle cost for all 58 locales.
- **Pen detection is automatic:** Users with styluses don't need to configure anything — the mode activates on first pen contact.
- **Platform-aware shortcut labels:** `getShortcutKey()` shows `⌘` on Mac and `Ctrl` elsewhere — shortcuts look correct on all platforms.

## Cons
- **No automatic system locale detection:** The app does not read `navigator.language` to set the initial locale — users must manually select their language on first use.
- **85% threshold is a binary cut-off:** A language at 84% completion shows no UI — no "partial translation" fallback mode.
- **Pen mode is one-shot detection:** If a user accidentally triggers pen mode with a stylus but wants to use mouse/touch, they must manually toggle it off via the PenModeButton — there is no auto-revert on mouse input.
- **No font support audit per locale:** CJK locales (Chinese, Japanese, Korean) require specific font loading. While there is a CJK font in `fonts/`, there is no guarantee all CJK codepoints in all translated strings are covered.
- **Help dialog is static HTML:** Shortcut changes anywhere in the codebase are not automatically reflected in `HelpDialog.tsx` — it can fall out of sync with actual shortcuts.
- **Crowdin CI integration requires external service:** `percentages.json` is only updated when Crowdin CI runs — a stale `percentages.json` could expose incomplete translations to users.

## Notes
- `en.json` is the source of truth for all translation keys. It is the TypeScript type source for `t()` path checking.
- Test locales (`__test__`, `__test__.rtl`) are used in automated tests to verify i18n rendering without depending on any specific language's translation completeness.
- `document.dir = "rtl"` is a document-level change — it affects the entire page, not just the editor component. Host applications embedding the Excalidraw library should be aware of this side effect.
