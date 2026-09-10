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

    property string country: "BE"
    property var inss: null
    property var iban: null
    property string message: ""

    function generateInss() {
        inss = Generator.generateInss()
        message = ""
    }
    function generateIban() {
        iban = Generator.generateIban(country)
        message = ""
    }
    function copyValue(value, label) {
        clipboardText.text = value
        clipboardText.selectAll()
        clipboardText.copy()
        clipboardText.deselect()
        message = label + " copied without separators"
        feedbackTimer.restart()
    }
    Component.onCompleted: {
        generateInss()
        generateIban()
    }
    onOpenedChanged: if (!opened) countryPicker.close()

    TextEdit { id: clipboardText; visible: false }
    Timer { id: feedbackTimer; interval: 2500; onTriggered: root.message = "" }

    Ui.BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "󰗠"
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
        contentWidth: fittedContentWidth(Style.space(440))
        contentHeight: fittedContentHeight(column.implicitHeight, Style.space(620))

        Item {
            id: content
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.close()

            Controls.ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    id: column
                    width: parent.width
                    spacing: Style.space(14)

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Yenerator"
                            font.family: Style.font.family
                            font.pixelSize: Style.font.body * 1.5
                            font.bold: true
                            color: Color.foreground
                            Layout.fillWidth: true
                        }
                        Ui.Button {
                            text: "Close"
                            focusable: true
                            onClicked: root.close()
                        }
                    }
                    Text {
                        text: "Fresh mock data, one click away."
                        color: Color.muted
                        font.family: Style.font.family
                        font.pixelSize: Style.font.bodySmall
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true }
                    Text {
                        text: "INSS · Rijksregisternummer"
                        font.family: Style.font.family
                        font.pixelSize: Style.font.body
                        font.bold: true
                        color: Color.foreground
                    }
                    Ui.TextField {
                        text: root.inss ? root.inss.formatted : ""
                        readOnly: true
                        selectByMouse: true
                        Accessible.name: "Generated Belgian INSS"
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.inss ? "Belgium · " + root.inss.birthDate + " · " + root.inss.sex : ""
                        color: Color.muted
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                    }
                    RowLayout {
                        Ui.Button {
                            text: "Generate INSS"
                            bordered: true
                            focusable: true
                            onClicked: root.generateInss()
                        }
                        Ui.Button {
                            text: "Copy INSS"
                            focusable: true
                            enabled: root.inss !== null
                            onClicked: root.copyValue(root.inss.raw, "INSS")
                        }
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true }
                    Ui.Dropdown {
                        id: countryPicker
                        label: "IBAN country"
                        value: root.country
                        options: Generator.countries.map(function(c) {
                            return { value: c.code, label: c.name + " (" + c.code + ")" }
                        })
                        Layout.fillWidth: true
                        onChanged: function(value) {
                            root.country = value
                            root.generateIban()
                        }
                    }
                    Ui.TextField {
                        text: root.iban ? root.iban.formatted : ""
                        readOnly: true
                        selectByMouse: true
                        Accessible.name: "Generated IBAN"
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        Ui.Button {
                            text: "Generate IBAN"
                            bordered: true
                            focusable: true
                            onClicked: root.generateIban()
                        }
                        Ui.Button {
                            text: "Copy IBAN"
                            focusable: true
                            enabled: root.iban !== null
                            onClicked: root.copyValue(root.iban.raw, "IBAN")
                        }
                    }
                    Text {
                        text: root.message || "Copy buttons remove spaces and punctuation."
                        color: root.message ? Color.accent : Color.muted
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true }
                    Text {
                        text: "MOCK DATA ONLY\nValid checksums. Values may coincide with real identifiers; bank acceptance is not guaranteed."
                        color: Color.muted
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
