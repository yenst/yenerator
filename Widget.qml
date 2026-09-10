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

    property string icon: setting("icon", "\uF2C3")
    property string country: "BE"
    property var inss: null
    property var bsn: null
    property var iban: null
    property var email: null
    property string selectedKind: "INSS"
    property string copiedKind: ""
    readonly property bool hasInss: country === "BE"
    readonly property bool hasBsn: country === "NL"
    readonly property var visibleRows: {
        var rows = []
        if (hasInss) rows.push(inssRow)
        if (hasBsn) rows.push(bsnRow)
        rows.push(ibanRow)
        rows.push(emailRow)
        return rows
    }
    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
    readonly property color muted: Qt.darker(foreground, 1.4)

    function refresh() {
        inss = hasInss ? Generator.generateInss() : null
        bsn = hasBsn ? Generator.generateBsn() : null
        iban = Generator.generateIban(country)
        email = Generator.generateEmail()
        copiedKind = ""
        feedbackTimer.stop()
        selectedKind = visibleRows[selectedRowIndex()].kind
    }
    function selectCountry(value) {
        if (country === value) return
        country = value
        selectedKind = visibleRows[0].kind
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
    function selectedRowIndex() {
        for (var i = 0; i < visibleRows.length; i += 1) {
            if (visibleRows[i].kind === selectedKind) return i
        }
        return 0
    }
    function copySelected() {
        var row = visibleRows[selectedRowIndex()]
        if (row.record) copyValue(row.record.raw, row.kind)
    }
    function moveRow(direction) {
        var index = Math.max(0, Math.min(visibleRows.length - 1, selectedRowIndex() + direction))
        var row = visibleRows[index]
        selectedKind = row.kind
        row.forceActiveFocus(Qt.TabFocusReason)
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
        tooltipText: "Yenerator"
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
                        label: "Country for identity and banking fields"
                        showLabel: false
                        value: root.country
                        foreground: root.foreground
                        fontFamily: root.fontFamily
                        Accessible.name: "Country for identity and banking fields"
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
                        record: root.inss
                        detail: root.inss ? root.inss.birthDate + " · " + root.inss.sex : ""
                    }
                    RecordRow {
                        id: bsnRow
                        objectName: "bsnRow"
                        visible: root.hasBsn
                        kind: "BSN"
                        title: "BURGERSERVICENUMMER · BSN"
                        record: root.bsn
                    }
                    RecordRow {
                        id: ibanRow
                        objectName: "ibanRow"
                        kind: "IBAN"
                        title: "IBAN"
                        record: root.iban
                    }
                    RecordRow {
                        id: emailRow
                        objectName: "emailRow"
                        kind: "Email"
                        title: "EMAIL"
                        record: root.email
                    }
                    Text {
                        visible: !root.hasInss && !root.hasBsn
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
                        textFormat: root.copiedKind ? Text.PlainText : Text.RichText
                        text: root.copiedKind ? root.copiedKind + " copied" + (root.copiedKind === "Email" ? "" : " · without separators") : "<b>R</b>efresh&nbsp;&nbsp; <b>C</b>opy"
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
        required property var record
        readonly property string value: record ? record.formatted : ""
        property string detail: ""
        Layout.fillWidth: true
        implicitHeight: labels.implicitHeight + Style.space(16)
        foreground: root.foreground
        hasCursor: root.selectedKind === kind && !countryPicker.popupOpen
        activeFocusOnTab: visible
        onActiveFocusChanged: if (activeFocus && visible) root.selectedKind = kind
        Accessible.role: Accessible.ListItem
        Accessible.name: title + ": " + value
        Accessible.description: kind === "Email" ? "Press C to copy the email address. Press R to regenerate all fields." : "Press C to copy without separators. Press R to regenerate all fields."
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
