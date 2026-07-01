pragma Singleton
pragma ComponentBehavior: Bound

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.utils

Searcher {
    id: root

    readonly property string edpScript: `${Quickshell.env("HOME")}/.local/bin/edp-res`
    readonly property string edpPrefix: `${GlobalConfig.launcher.actionPrefix}edp `
    readonly property string customPrefix: `${GlobalConfig.launcher.actionPrefix}edp custom `

    function transformSearch(search: string): string {
        return search.slice(edpPrefix.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.description ?? item.desc ?? ""} ${item.mode ?? ""}`;
    }

    function normaliseMode(raw: string): string {
        let mode = raw.replace(/\s+/g, "");

        if (!mode)
            return "";

        if (!mode.includes("@"))
            mode = `${mode}@60`;

        return mode;
    }

    function validMode(mode: string): bool {
        return /^[0-9]{3,5}x[0-9]{3,5}@[0-9]+(\.[0-9]+)?$/.test(mode);
    }

    function notify(title: string, body: string): void {
        Quickshell.execDetached(["notify-send", "-a", "edp-res", title, body]);
    }

    function run(launcherList: var, command: var): void {
        launcherList.visibilities.launcher = false;
        Quickshell.execDetached(command);
    }

    function queryEdp(search: string): var {
        if (search.startsWith(customPrefix)) {
            const mode = normaliseMode(search.slice(customPrefix.length));

            return [{
                name: mode ? `EDP Custom ${mode}` : "EDP Custom",
                icon: "edit",
                description: mode
                    ? "Wciśnij Enter, aby zastosować tę rozdzielczość"
                    : "Wpisz np. >edp custom 1920x1080@60",
                desc: mode
                    ? "Wciśnij Enter, aby zastosować tę rozdzielczość"
                    : "Wpisz np. >edp custom 1920x1080@60",
                mode: mode,
                onClicked: function(launcherList) {
                    if (!mode) {
                        launcherList.search.text = customPrefix;
                        return;
                    }

                    if (!validMode(mode)) {
                        notify("Niepoprawna rozdzielczość", "Użyj formatu np. 1920x1080@60 albo 1920x1080");
                        return;
                    }

                    run(launcherList, [edpScript, "force", mode]);
                }
            }];
        }

        return query(search);
    }

    list: [
        Mode {
            name: "EDP Auto"
            icon: "display_settings"
            description: "Automatycznie dobierz rozdzielczość laptopa/mirrora"
            command: [root.edpScript, "apply"]
        },
        Mode {
            name: "EDP Mirror 1080p"
            icon: "monitor"
            description: "Ustaw 1920x1080@60 dla mirrorowanego monitora Full HD"
            mode: "1920x1080@60"
            command: [root.edpScript, "force", "1920x1080@60"]
        },
        Mode {
            name: "EDP Laptop 1200p"
            icon: "laptop"
            description: "Ustaw 1920x1200@60 dla pracy tylko na laptopie"
            mode: "1920x1200@60"
            command: [root.edpScript, "force", "1920x1200@60"]
        },
        Mode {
            name: "EDP Custom"
            icon: "edit"
            description: "Wpisz własną rozdzielczość: >edp custom 1920x1080@60"
            command: []
            custom: true
        },
        Mode {
            name: "EDP Status"
            icon: "info"
            description: "Pokaż aktualny status rozdzielczości i mirrora"
            command: [root.edpScript, "status-notify"]
        }
    ]

    component Mode: QtObject {
        required property string name
        required property string icon
        required property string description

        readonly property string desc: description

        property string mode: ""
        property var command: []
        property bool custom: false

        function onClicked(launcherList: var): void {
            if (custom) {
                launcherList.search.text = root.customPrefix;
                return;
            }

            root.run(launcherList, command);
        }
    }
}