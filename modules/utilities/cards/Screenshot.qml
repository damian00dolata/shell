pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property DrawerVisibilities visibilities

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: {
                const h = icon.implicitHeight + Tokens.padding.small * 2;
                return h - (h % 2);
            }

            radius: Tokens.rounding.full
            color: Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: "photo_camera"
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.large
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Screenshot")
            font: Tokens.font.body.medium
            elide: Text.ElideRight
        }

        ButtonRow {
            spacing: Tokens.spacing.extraSmall

            IconButton {
                icon: "fullscreen"
                font: Tokens.font.icon.medium
                onClicked: {
                    root.visibilities.utilities = false;
                    Quickshell.execDetached(["caelestia", "screenshot"]);
                }

                implicitWidth: {
                    const h = label.implicitHeight + Tokens.padding.large * 2;
                    if (h % 2 !== 0)
                        return h + 1;
                    return h;
                }
            }

            IconButton {
                icon: "screenshot_region"
                font: Tokens.font.icon.medium
                onClicked: {
                    root.visibilities.utilities = false;
                    Quickshell.execDetached(["caelestia", "screenshot", "-r"]);
                }

                implicitWidth: {
                    const h = label.implicitHeight + Tokens.padding.large * 2;
                    if (h % 2 !== 0)
                        return h + 1;
                    return h;
                }
            }

            IconButton {
                icon: "ac_unit"
                font: Tokens.font.icon.medium
                onClicked: {
                    root.visibilities.utilities = false;
                    Quickshell.execDetached(["caelestia", "screenshot", "-r", "-f"]);
                }

                implicitWidth: {
                    const h = label.implicitHeight + Tokens.padding.large * 2;
                    if (h % 2 !== 0)
                        return h + 1;
                    return h;
                }
            }

            IconButton {
                icon: "timer_3"
                font: Tokens.font.icon.medium
                onClicked: {
                    root.visibilities.utilities = false;
                    Quickshell.execDetached(["sh", "-c", "sleep 3 && caelestia screenshot"]);
                }

                implicitWidth: {
                    const h = label.implicitHeight + Tokens.padding.large * 2;
                    if (h % 2 !== 0)
                        return h + 1;
                    return h;
                }
            }
        }
    }
}
