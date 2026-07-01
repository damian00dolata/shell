# Example: Native EDP Launcher Provider

Goal: Add native Caelestia launcher actions for eDP/mirror resolution management.

Expected launcher UX:

```text
>edp
EDP Auto
EDP Mirror 1080p
EDP Laptop 1200p
EDP Custom
EDP Status
```

Custom resolution:

```text
>edp custom 1920x1080@60
>edp custom 1920x1080
```

Files touched:

```text
modules/launcher/AppList.qml
modules/launcher/services/EdpModes.qml
plugin/src/Caelestia/Config/launcherconfig.hpp
```

Do not use a custom item delegate unless necessary. Reuse `actionItem` and return action-like objects with `name`, `icon`, `desc`, and `onClicked`.

`AppList.qml` changes:

```qml
for (const action of ["calc", "scheme", "variant", "edp"])
    if (text.startsWith(`${prefix}${action} `))
        return action;
```

Add state:

```qml
State {
    name: "edp"

    PropertyChanges {
        model.values: EdpModes.queryEdp(search.text)
        root.delegate: actionItem
    }
}
```

`launcherconfig.hpp` default action:

```cpp
vmap({
    { u"name"_s, u"EDP"_s },
    { u"icon"_s, u"display_settings"_s },
    { u"description"_s, u"Change eDP/mirror resolution"_s },
    { u"command"_s, QStringList{ u"autocomplete"_s, u"edp"_s } },
}),
```

QML gotchas:

- Use `function queryEdp(search: string): var`, not `: list`.
- Use `property var command: []`, not `property list command: []`.
- Avoid `function(list)`; use `function(launcherList)`.
- If using `ActionItem`, expose `desc`, not only `description`.
