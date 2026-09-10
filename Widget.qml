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

    property string icon: setting("icon", "\uDB84\uDD56")
    property string country: "BE"
    property var inss: null
    property var iban: null
    property string selectedKind: "INSS"
    property string copiedKind: ""
    readonly property bool hasInss: country === "BE"
    onSelectedKindChanged: if (!hasInss && selectedKind === "INSS") selectedKind = "IBAN"
    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
    readonly property color muted: Qt.darker(foreground, 1.4)

    function refresh() {
        inss = hasInss ? Generator.generateInss() : null
        iban = Generator.generateIban(country)
        copiedKind = ""
        feedbackTimer.stop()
        if (!hasInss) selectedKind = "IBAN"
    }
    function selectCountry(value) {
        if (country === value) return
        country = value
        selectedKind = hasInss ? "INSS" : "IBAN"
        refresh()
    }
    function copyValue(value, label) {
        clipboardText.text = value
        clipboardText.selectAll()
        clipboardText.copy()
        clipboardText.deselect()
        copiedKind = label
        feedbackTimer.restart()
    }
    function copySelected() {
        var record = selectedKind === "INSS" && hasInss ? inss : iban
        if (record) copyValue(record.raw, selectedKind === "INSS" && hasInss ? "INSS" : "IBAN")
    }
    function moveRow(direction) {
        selectedKind = hasInss && direction < 0 ? "INSS" : "IBAN"
        if (selectedKind === "INSS") inssRow.forceActiveFocus(Qt.TabFocusReason)
        else ibanRow.forceActiveFocus(Qt.TabFocusReason)
    }
    function handleKey(event) {
        if (!opened || countryPicker.popupOpen) return
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
        switch (event.key) {
        case Qt.Key_R:
            if (!event.isAutoRepeat) refresh()
            event.accepted = true
            break
        case Qt.Key_C:
            if (!event.isAutoRepeat) copySelected()
            event.accepted = true
            break
        case Qt.Key_Up:
            moveRow(-1)
            event.accepted = true
            break
        case Qt.Key_Down:
            moveRow(1)
            event.accepted = true
            break
        case Qt.Key_Escape:
            close()
            event.accepted = true
            break
        }
    }
    Component.onCompleted: refresh()
    onOpenedChanged: {
        if (!opened) countryPicker.close()
    }

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
            Keys.onPressed: function(event) { root.handleKey(event) }

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
                    spacing: Style.space(12)

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
                    Ui.Dropdown {
                        id: countryPicker
                        objectName: "countryPicker"
                        Layout.fillWidth: true
                        label: "Country for all fields"
                        showLabel: false
                        value: root.country
                        foreground: root.foreground
                        fontFamily: root.fontFamily
                        Accessible.name: "Country for all fields"
                        options: Generator.countries.map(function(c) {
                            return { value: c.code, label: c.name + " (" + c.code + ")" }
                        })
                        onChanged: function(value) { root.selectCountry(value) }
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

                    RecordRow {
                        id: inssRow
                        objectName: "inssRow"
                        visible: root.hasInss
                        kind: "INSS"
                        title: "RIJKSREGISTERNUMMER · INSS"
                        value: root.inss ? root.inss.formatted : ""
                        detail: root.inss ? root.inss.birthDate + " · " + root.inss.sex : ""
                    }
                    RecordRow {
                        id: ibanRow
                        objectName: "ibanRow"
                        kind: "IBAN"
                        title: "IBAN"
                        value: root.iban ? root.iban.formatted : ""
                    }
                    Text {
                        visible: !root.hasInss
                        Layout.fillWidth: true
                        text: "INSS is available for Belgium only."
                        color: root.muted
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        wrapMode: Text.WordWrap
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }
                    Text {
                        Layout.fillWidth: true
                        textFormat: Text.PlainText
                        text: root.copiedKind ? root.copiedKind + " copied · without separators" : "R  Refresh all    C  Copy row    ↑↓  Select"
                        color: root.copiedKind ? root.foreground : root.muted
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    component RecordRow: Ui.CursorSurface {
        id: row
        required property string kind
        required property string title
        required property string value
        property string detail: ""
        Layout.fillWidth: true
        implicitHeight: labels.implicitHeight + Style.space(16)
        foreground: root.foreground
        hasCursor: root.selectedKind === kind && !countryPicker.popupOpen
        activeFocusOnTab: visible
        onActiveFocusChanged: if (activeFocus && visible) root.selectedKind = kind
        Accessible.role: Accessible.ListItem
        Accessible.name: title + ": " + value
        Accessible.description: "Press C to copy without separators. Press R to regenerate all fields."
        Accessible.onPressAction: { root.selectedKind = kind; root.copySelected() }
        Keys.onPressed: function(event) { root.handleKey(event) }

        ColumnLayout {
            id: labels
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Style.space(8)
            spacing: Style.space(4)
            RowLayout {
                Layout.fillWidth: true
                Ui.PanelSectionHeader {
                    Layout.fillWidth: true
                    text: row.title
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                }
                Text {
                    text: root.copiedKind === row.kind ? "Copied" : "C"
                    visible: row.hasCursor || root.copiedKind === row.kind
                    color: root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                textFormat: Text.PlainText
                text: row.value
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.heading
                wrapMode: Text.WordWrap
            }
            Text {
                visible: row.detail !== ""
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: row.detail
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
            }
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: if (row.visible && !countryPicker.popupOpen) root.selectedKind = row.kind
            onPositionChanged: if (row.visible && !countryPicker.popupOpen) root.selectedKind = row.kind
            onClicked: row.forceActiveFocus(Qt.MouseFocusReason)
        }
    }
}
