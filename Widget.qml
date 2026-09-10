import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import qs.Commons
import qs.Ui as Ui
import "Generator.js" as Generator

Ui.Panel {
    id: root
    moduleName: "jihmy.yenerator"
    manageIpc: false
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    // Material Design Icons: dice-multiple-outline (U+F1156).
    property string icon: setting("icon", "\uDB84\uDD56")
    property string country: "BE"
    property var inss: null
    property var iban: null
    property string copiedKind: ""
    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
    readonly property color muted: Qt.darker(foreground, 1.4)

    function generateInss() {
        inss = Generator.generateInss()
        copiedKind = ""
    }
    function generateIban() {
        iban = Generator.generateIban(country)
        copiedKind = ""
    }
    function copyValue(value, label) {
        clipboardText.text = value
        clipboardText.selectAll()
        clipboardText.copy()
        clipboardText.deselect()
        copiedKind = label
        feedbackTimer.restart()
    }
    Component.onCompleted: {
        generateInss()
        generateIban()
    }
    onOpenedChanged: if (!opened) countryPicker.close()

    TextEdit { id: clipboardText; visible: false }
    Timer { id: feedbackTimer; interval: 2500; onTriggered: root.copiedKind = "" }

    Ui.BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.icon
        tooltipText: "Yenerator · mock data"
        onPressed: root.toggle()
    }

    Ui.KeyboardPanel {
        id: popup
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: content
        contentWidth: fittedContentWidth(Style.space(380))
        contentHeight: fittedContentHeight(column.implicitHeight)

        Item {
            id: content
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: {
                if (countryPicker.popupOpen) countryPicker.close()
                else root.close()
            }

            Controls.ScrollView {
                id: scroll
                anchors.fill: parent
                contentWidth: availableWidth
                activeFocusOnTab: false
                clip: true
                Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff

                ColumnLayout {
                    id: column
                    width: scroll.availableWidth
                    spacing: Style.space(14)

                    Ui.PanelHero {
                        Layout.fillWidth: true
                        title: "Yenerator"
                        meta: "Mock data"
                        foreground: root.foreground
                        fontFamily: root.fontFamily
                        iconComponent: Text {
                            textFormat: Text.PlainText
                            text: root.icon
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.display
                        }
                    }

                    Ui.PanelSeparator {
                        Layout.fillWidth: true
                        foreground: root.foreground
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(4)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.space(8)
                            Ui.PanelSectionHeader {
                                Layout.fillWidth: true
                                text: "BELGIAN INSS"
                                foreground: root.foreground
                                fontFamily: root.fontFamily
                            }
                            ActionButton {
                                iconText: "󰑐"
                                tooltipText: "Regenerate INSS"
                                onClicked: root.generateInss()
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.space(8)
                            ResultText {
                                text: root.inss ? root.inss.formatted : ""
                                Accessible.name: "Generated Belgian INSS: " + text
                            }
                            ActionButton {
                                iconText: root.copiedKind === "INSS" ? "󰄬" : "󰆏"
                                tooltipText: "Copy INSS without separators"
                                enabled: root.inss !== null
                                onClicked: root.copyValue(root.inss.raw, "INSS")
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            textFormat: Text.PlainText
                            text: root.inss ? root.inss.birthDate + " · " + root.inss.sex : ""
                            color: root.muted
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            wrapMode: Text.WordWrap
                        }
                    }

                    Ui.PanelSeparator {
                        Layout.fillWidth: true
                        foreground: root.foreground
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(8)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.space(8)
                            Ui.PanelSectionHeader {
                                Layout.fillWidth: true
                                text: "IBAN"
                                foreground: root.foreground
                                fontFamily: root.fontFamily
                            }
                            Ui.Dropdown {
                                id: countryPicker
                                Layout.preferredWidth: Math.min(Style.space(180), column.width * 0.6)
                                label: "IBAN country"
                                showLabel: false
                                value: root.country
                                foreground: root.foreground
                                fontFamily: root.fontFamily
                                Accessible.name: "IBAN country"
                                options: Generator.countries.map(function(c) {
                                    return { value: c.code, label: c.name + " (" + c.code + ")" }
                                })
                                onChanged: function(value) {
                                    root.country = value
                                    root.generateIban()
                                }
                            }
                            ActionButton {
                                iconText: "󰑐"
                                tooltipText: "Regenerate IBAN"
                                onClicked: root.generateIban()
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.space(8)
                            ResultText {
                                text: root.iban ? root.iban.formatted : ""
                                Accessible.name: "Generated IBAN: " + text
                            }
                            ActionButton {
                                Layout.alignment: Qt.AlignTop
                                iconText: root.copiedKind === "IBAN" ? "󰄬" : "󰆏"
                                tooltipText: "Copy IBAN without separators"
                                enabled: root.iban !== null
                                onClicked: root.copyValue(root.iban.raw, "IBAN")
                            }
                        }
                    }

                    Ui.PanelSeparator {
                        Layout.fillWidth: true
                        foreground: root.foreground
                    }

                    Text {
                        Layout.fillWidth: true
                        textFormat: Text.PlainText
                        text: root.copiedKind ? root.copiedKind + " copied · without separators" : "Copy without separators"
                        color: root.copiedKind ? root.foreground : root.muted
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    component ResultText: Text {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        wrapMode: Text.WordWrap
        Accessible.role: Accessible.StaticText
    }

    component ActionButton: Ui.PanelActionButton {
        foreground: root.foreground
        fontFamily: root.fontFamily
        focusable: true
        Accessible.role: Accessible.Button
        Accessible.name: tooltipText
        Accessible.onPressAction: clicked()
    }
}
