---
name: claude-caelestia-skill
description: Guidance for working inside a personal fork of the Caelestia Quickshell shell repository: navigation, launcher internals, QML services/items, config defaults, build/install workflow, debugging, Git hygiene, and best practices.
---

# Caelestia Shell Development Skill

Use this skill when working in the user's Caelestia shell fork, usually located at:

```sh
~/.config/quickshell/caelestia
```

The user runs Arch Linux + Hyprland + Quickshell + Caelestia. They use a custom branch named `custom` and want changes made in the fork rather than as fragile external scripts whenever the feature logically belongs in Caelestia.

## Operating principles

Prefer native Caelestia integration over external UI hacks when the requested feature belongs in the shell. Reuse existing QML services, launcher item delegates, tokenized styling, and config objects before creating new UI from scratch.

Keep local runtime configuration separate from source code:

- Source/fork code lives in `~/.config/quickshell/caelestia`.
- User config lives in `~/.config/caelestia/shell.json`.
- Do not commit `~/.config/caelestia/shell.json` unless the user explicitly maintains dotfiles there.
- Do not commit generated or installer-touched files such as `shell.qml` unless the diff is intentional and understood.

When changing QML only, restart Caelestia. When changing C++ plugin/config code under `plugin/src`, rebuild and install the plugin, then restart Caelestia.

## Repository map

High-value paths:

```text
shell.qml                                      Main shell entrypoint. Usually do not edit casually.
modules/bar/                                  Bar, workspaces, status modules.
modules/drawers/                              Drawer host and panel containers.
modules/launcher/                             Launcher UI and routing.
modules/launcher/AppList.qml                  Launcher state router: apps/actions/calc/scheme/variant/custom states.
modules/launcher/items/                       Launcher row delegates such as AppItem, ActionItem, SchemeItem, VariantItem.
modules/launcher/services/                    Search/data providers such as Apps, Actions, Schemes, M3Variants.
modules/notifications/                        Notifications UI and notification rendering.
modules/session/                              Session/power menu related UI.
modules/osd/                                  OSD overlays.
modules/utilities/ or related drawer panels    Utilities/dashboard panels, depending on upstream version.
plugin/src/Caelestia/Config/                  C++ config defaults exposed to QML.
plugin/src/Caelestia/Config/launcherconfig.hpp Default launcher configuration and default action list.
README.md                                     Upstream configuration reference and examples.
```

Use ripgrep before editing:

```sh
cd ~/.config/quickshell/caelestia
rg -n 'launcher|Actions|Scheme|Variant|GlobalShortcut|caelestia:' .
rg -n 'CONFIG_.*PROPERTY|launcherconfig|actions' plugin/src
rg -n 'State \{|model.values|delegate:' modules/launcher
```

## Launcher architecture

The launcher is structured as a router plus providers plus item delegates.

Typical flow:

1. User types in the launcher search field.
2. `modules/launcher/AppList.qml` decides which state should be active.
3. The active state assigns `model.values` from a service/provider.
4. The active state assigns a delegate such as `appItem`, `actionItem`, `schemeItem`, or `variantItem`.
5. The delegate displays each result and handles click/activation.

Important files:

```text
modules/launcher/AppList.qml
modules/launcher/services/Actions.qml
modules/launcher/services/Apps.qml
modules/launcher/services/Schemes.qml
modules/launcher/services/M3Variants.qml
modules/launcher/items/ActionItem.qml
modules/launcher/items/AppItem.qml
modules/launcher/items/SchemeItem.qml
modules/launcher/items/VariantItem.qml
```

To add a new launcher submode like `>edp`:

1. Add the submode name to the prefix detection loop in `AppList.qml`.
2. Add a new `State` in `AppList.qml`.
3. Implement a provider under `modules/launcher/services/`.
4. Reuse `actionItem` when the entries behave like actions.
5. Add the top-level launcher action to defaults in `plugin/src/Caelestia/Config/launcherconfig.hpp` if it should appear under `>` by default.

Example state pattern:

```qml
State {
    name: "edp"

    PropertyChanges {
        model.values: EdpModes.queryEdp(search.text)
        root.delegate: actionItem
    }
}
```

If using `actionItem`, returned objects should expose the fields that `ActionItem.qml` expects. In this fork, action-like objects should provide at least:

```qml
{
    name: "Action Name",
    icon: "material_icon_name",
    desc: "Short description",
    onClicked: function(launcherList) { ... }
}
```

If the object has only `description`, add a `desc` alias or map it before handing it to `ActionItem`.

## Default launcher actions

The default `>` action list is defined in:

```text
plugin/src/Caelestia/Config/launcherconfig.hpp
```

Look for:

```cpp
CONFIG_GLOBAL_PROPERTY(QVariantList, actions, { ... })
```

Actions are stored as `vmap({ ... })` entries. Add a new action near related entries, for example after `Variant`:

```cpp
vmap({
    { u"name"_s, u"EDP"_s },
    { u"icon"_s, u"display_settings"_s },
    { u"description"_s, u"Change eDP/mirror resolution"_s },
    { u"command"_s, QStringList{ u"autocomplete"_s, u"edp"_s } },
}),
```

Do not add `launcher.actions` to `~/.config/caelestia/shell.json` unless you intentionally want to override the entire default action list. A partial `launcher.actions` list in `shell.json` may hide default actions such as Scheme, Variant, Wallpaper, Light, Dark, Settings, etc.

## User config: `shell.json`

User runtime config is usually:

```text
~/.config/caelestia/shell.json
```

Current important local preferences may include:

```json
{
  "appearance": {
    "transparency": {
      "enabled": false
    }
  },
  "bar": {
    "showOnHover": true,
    "status": {
      "showBattery": true,
      "showBluetooth": true,
      "showLockStatus": true,
      "showNetwork": true,
      "showWifi": true
    },
    "workspaces": {
      "perMonitorWorkspaces": true,
      "shown": 10
    }
  }
}
```

Validate after editing:

```sh
jq empty ~/.config/caelestia/shell.json
```

## QML best practices

Use existing design tokens and components:

```qml
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
```

Prefer:

- `Tokens.spacing.*`, `Tokens.padding.*`, `Tokens.rounding.*`, `Tokens.sizes.*`
- `Colours.palette.*`
- Existing delegates such as `ActionItem` when possible
- Existing services and `Searcher` patterns when building query providers

Avoid hardcoding `/home/dad`. Use:

```qml
Quickshell.env("HOME") + "/.local/bin/tool"
```

Run external commands with:

```qml
Quickshell.execDetached(["command", "arg1", "arg2"])
```

Use JavaScript arrays as `var`, not `list`, unless the list has an explicit QML element type.

Bad:

```qml
function querySomething(search: string): list { ... }
property list command: []
```

Good:

```qml
function querySomething(search: string): var { ... }
property var command: []
```

Avoid using `list` as a parameter name in functions. Qt/QML may parse it as a type and fail with errors like:

```text
list is not a type. It requires an element type argument (eg. list<int>)
```

Use names like `launcherList`, `view`, `ctx`, or `owner` instead.

## Restart and debugging

The user's Hyprland config starts Caelestia approximately as:

```sh
env QT_QPA_PLATFORMTHEME=qt6ct caelestia shell -d
```

Use the same environment variable when restarting manually:

```sh
pkill -f 'caelestia shell' 2>/dev/null
pkill -f 'quickshell.*caelestia' 2>/dev/null
pkill -f 'qs.*caelestia' 2>/dev/null

setsid -f env QT_QPA_PLATFORMTHEME=qt6ct caelestia shell -d \
  >/tmp/caelestia-shell.log 2>&1
```

If it fails:

```sh
tail -n 160 /tmp/caelestia-shell.log
```

Quickshell may also write logs under:

```sh
find /run/user/$UID/quickshell/by-id -name log.qslog -printf '%T@ %p\n' | sort -nr | head
```

Read the newest log:

```sh
log="$(find /run/user/$UID/quickshell/by-id -name log.qslog -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)"
tail -n 160 "$log"
```

Useful filters:

```sh
rg -i 'error|typeerror|failed|launcher|AppList|EdpModes|qml' /tmp/caelestia-shell.log
```

## Build and install workflow

QML-only changes generally require only a shell restart. C++ plugin changes under `plugin/src` require rebuild and install:

```sh
cd ~/.config/quickshell/caelestia

cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/ \
  -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"

cmake --build build
sudo cmake --install build
sudo chown -R "$USER":"$(id -gn)" "$HOME/.config/quickshell/caelestia"
```

If a C++ default did not seem to update, clean rebuild:

```sh
rm -rf build
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/ \
  -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"
cmake --build build
sudo cmake --install build
```

Check whether installed plugin contains a new default string:

```sh
strings /usr/lib/qt6/qml/Caelestia/lib/libcaelestia-config.so | rg 'EDP|edp|display_settings'
```

## Git workflow and hygiene

Default branch for user customizations:

```sh
git switch custom
```

For larger features:

```sh
git switch -c feat/<feature-name>
```

Before commit:

```sh
git status --short --untracked-files=all
git diff --stat
git diff -- <file>
```

Do not commit leftover files from abandoned approaches. Example: if `modules/launcher/items/EdpModeItem.qml` was created but the final implementation uses `actionItem`, remove it.

Be cautious with `shell.qml`. The install step may touch it. Inspect before committing:

```sh
git diff -- shell.qml
```

If not intentional:

```sh
git restore -- shell.qml
```

Commit only related files:

```sh
git add modules/launcher/AppList.qml \
        modules/launcher/services/EdpModes.qml \
        plugin/src/Caelestia/Config/launcherconfig.hpp

git commit -m "feat(launcher): add EDP resolution actions"
```

## Hyprland and global shortcuts

## Hyprland integration

The user's primary Hyprland config lives at:

```text
~/.config/hypr/hyprland.conf
```

Use this file when a Caelestia feature needs compositor integration, especially:

- keybinds for Caelestia global shortcuts;
- launcher, sidebar, dashboard, session menu, screenshot, lock, and media binds;
- autostart of `caelestia shell -d`;
- monitor and mirror behavior that affects Caelestia UI or helper actions;
- layer rules only when Caelestia layers need compositor-side treatment.

Do not treat Hyprland configuration as part of the Caelestia source repository. It belongs to the user's dotfiles/system config, not to the Caelestia fork.

For source changes, stay in:

```text
~/.config/quickshell/caelestia
```

For compositor/user-session changes, inspect or edit:

```text
~/.config/hypr/hyprland.conf
~/.config/hypr/hyprpaper.conf
~/.config/hypr/Scripts/
~/.local/bin/
~/.config/systemd/user/
```

Common checks:

```sh
hyprctl configerrors
hyprctl reload
hyprctl binds
hyprctl globalshortcuts
hyprctl layers
hyprctl monitors all
```

Known local Caelestia start pattern in Hyprland:

```ini
exec-once = env QT_QPA_PLATFORMTHEME=qt6ct caelestia shell -d
```

Known useful Caelestia global shortcut pattern:

```ini
bindi = SUPER, SUPER_L, global, caelestia:launcher
bindi = SUPER, SUPER_R, global, caelestia:launcher
bindin = SUPER, catchall, global, caelestia:launcherInterrupt
bind = SUPER, N, global, caelestia:sidebar
bind = CTRL ALT, DELETE, global, caelestia:session
```

When modifying Hyprland binds, preserve the user's existing workflows unless explicitly asked to replace them:

- `SUPER+N` for Caelestia sidebar;
- `SUPER+R` / `SUPER+Down` may still be Wofi fallback launchers;
- `SUPER+Up` is a custom active-window switcher;
- `SUPER+L` uses `hyprlock` and should not be replaced with Caelestia lock without confirmation;
- `SUPER+SHIFT+S` is scratchpad-related and should not be reused for screenshots;
- hyprsplit workspace binds use `split:workspace` and `split:movetoworkspacesilent`.

When a Caelestia change requires a Hyprland bind, propose the exact `bind`, `bindl`, `bindi`, or `bindin` line and tell the user that it belongs in `~/.config/hypr/hyprland.conf`, not in the Caelestia repo.

## Project-specific notes

The user has an `edp-res` script at:

```text
~/.local/bin/edp-res
```

Common commands:

```sh
~/.local/bin/edp-res apply
~/.local/bin/edp-res force 1920x1080@60
~/.local/bin/edp-res force 1920x1200@60
~/.local/bin/edp-res status-notify
```

Reasoning:

- The laptop panel is `eDP-1` / BOE panel.
- Mirrored external monitors copy the laptop source.
- For a Full HD mirror, the practical fix is often to set the laptop source to `1920x1080@60`.
- For laptop-only mode, use `1920x1200@60`.

A native launcher provider can expose:

```text
>edp
EDP Auto
EDP Mirror 1080p
EDP Laptop 1200p
EDP Custom
EDP Status
```

Custom mode pattern:

```text
>edp custom 1920x1080@60
>edp custom 1920x1080
```

The provider should normalize missing refresh rate to `@60` and validate the format before running `edp-res force`.

## Quality checklist for a new Caelestia feature

Before declaring done:

1. Search existing code for similar patterns.
2. Reuse existing components and delegates if possible.
3. Keep local user config separate from fork source.
4. Use `var` for JavaScript arrays in QML.
5. Avoid hardcoded home paths.
6. Restart shell for QML changes.
7. Rebuild plugin for C++ config/default changes.
8. Check `/tmp/caelestia-shell.log` and newest Quickshell log.
9. Validate that the shell starts cleanly.
10. Test the feature from the actual launcher/panel, not only from commands.
11. Inspect `git status` and remove abandoned files.
12. Commit only relevant files with a focused message.
