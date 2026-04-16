# Localization (i18n)

## What It Does
The app UI is fully translatable. Translation strings are loaded from plain-text files in the `res://Assets/I18n/` folder. The active language is configurable in Settings > General. A custom parser loads these files instead of Godot's built-in `.po`/`.csv` translation system.

## How to Use It
- **Settings > General > Language** dropdown to change the language
- Changes take effect immediately with no restart required
- English is shown first in the list; other languages are sorted alphabetically below a separator

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| I18nParser | `lorien/Misc/I18nParser.gd` | 1–107 | Reads and registers translation files; supports `{shortcut_list}` template |
| StringTemplating | `lorien/Misc/StringTemplating.gd` | — | Generic string template processor used by I18nParser |
| Settings | `lorien/Misc/Settings.gd` | 37–41 | `reload_locales()` — triggers I18nParser, sets active locale |
| SettingsDialog | `lorien/UI/Dialogs/SettingsDialog.gd` | 111–128 | Populates language dropdown sorted alphabetically |
| GlobalSignals | `lorien/Misc/GlobalSignals.gd` | — | `language_changed` signal broadcast to all UI components |
| Statusbar | `lorien/UI/Statusbar.gd` | 20–31 | Connects to `language_changed`, re-translates labels |
| SettingsDialog | `lorien/UI/Dialogs/SettingsDialog.gd` | 54–58 | Connects to `language_changed`, re-translates tab titles |
| I18n files | `lorien/Assets/I18n/` | — | One file per locale (filename = locale code, e.g. `en`, `de`, `fr`) |

## Architecture Notes
The custom format is a plain-text file where:
- The first non-comment line must be `LANGUAGE_NAME <Display Name>`
- Remaining lines are `KEY value` (space-separated; one per line)
- `#` begins an inline comment
- `\n` in values is converted to a real newline

The parser supports one template function: `{shortcut_list:action_name}` which is resolved at parse time to the current key bindings for that action. This means translation strings like `"Undo ({shortcut_list:shortcut_undo})"` automatically embed the user's configured shortcut.

`GlobalSignals.language_changed` is a global signal that any node can connect to in order to re-translate its labels when the language changes at runtime. The Statusbar and SettingsDialog both use this pattern.

`Settings.locales` and `Settings.language_names` are parallel arrays populated from `I18nParser.ParseResult` — the language dropdown is built from these.

## Pros
- Runtime language switching without restart is a nice UX improvement over most desktop apps
- Embedding shortcut hints directly in translation strings is elegant — localized help text stays current when bindings are remapped
- The custom plain-text format is simpler to edit than Gettext `.po` files — easier for community contributors to add translations
- The `GlobalSignals.language_changed` broadcast pattern allows any UI component to re-translate lazily without coupling to the settings system

## Cons / Limitations
- **Custom format means no tooling**: standard translation tools (Poedit, Transifex, Crowdin) cannot be used — all translations must be done manually in the custom format
- **Shortcut templates are resolved at parse time** (when the file is loaded), not at render time — if the user remaps a shortcut after launch, translation strings that include `{shortcut_list}` will show the old binding until the app restarts
- Translation files are embedded in the app's resource bundle (`res://`) — adding a new language requires recompiling the app (users cannot drop in a translation file at runtime)
- No fallback language: if a translation key is missing from the active locale, Godot shows the key name (e.g. `STATUSBAR_POSITION`) instead of the English string
- There is no translation completeness indicator — it's impossible to tell from within the app how complete a community translation is

## Decision Guidance
Localization is a well-considered feature given the custom shortcut-embedding capability. The main practical limitation is the custom format preventing use of professional translation tooling. For a community-translated open-source app, migrating to standard `.po` files would lower the barrier to contribution. The shortcut template resolution timing issue is a minor but user-visible bug worth fixing (resolve at render time, not parse time).
