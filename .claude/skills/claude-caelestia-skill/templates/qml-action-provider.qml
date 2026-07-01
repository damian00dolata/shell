pragma Singleton
pragma ComponentBehavior: Bound

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.utils

Searcher {
    id: root

    readonly property string actionPrefix: `${GlobalConfig.launcher.actionPrefix}example `

    function transformSearch(search: string): string {
        return search.slice(actionPrefix.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.desc ?? item.description ?? ""}`;
    }

    function run(launcherList: var, command: var): void {
        launcherList.visibilities.launcher = false;
        Quickshell.execDetached(command);
    }

    function queryExample(search: string): var {
        return query(search);
    }

    list: [
        Mode {
            name: "Example Action"
            icon: "settings"
            description: "Describe what this action does"
            command: ["notify-send", "Example", "Action executed"]
        }
    ]

    component Mode: QtObject {
        required property string name
        required property string icon
        required property string description

        readonly property string desc: description
        property var command: []

        function onClicked(launcherList: var): void {
            root.run(launcherList, command);
        }
    }
}
