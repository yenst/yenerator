import QtQuick
import QtTest
import Quickshell
import qs.Commons
import qs.Ui as Ui
import "Plugin" as Plugin
ShellRoot {
    id: harness
    property bool ready: false
    property var popup: null
    property string capturedValue: ""
    property string capturedKind: ""
    Ui.PluginBarApi {
        id: previewBar
        pluginId: "yenerator.test"
        moduleName: "yenerator.test"
        foreground: Color.foreground
        barForeground: Color.foreground
        fontFamily: Style.font.family
        barSize: Style.bar.sizeHorizontal
    }
    Plugin.Widget {
        id: widget
        bar: previewBar
        // Capture copy dispatch without changing the user's clipboard.
        function copyValue(value, label) {
            harness.capturedValue = value
            harness.capturedKind = label
        }
    }
    function popupOf(obj) {
        if (obj && "cardOrigin" in obj) return obj
        var items = obj && obj.data ? obj.data : []
        for (var i=0;i<items.length;i++) { var p=popupOf(items[i]); if(p) return p }
        return null
    }
    Timer { interval: 500; running: true; onTriggered: {
        harness.popup = harness.popupOf(widget)
        tests.parent = harness.popup.contentItem[0]
        widget.open()
        start.start()
    } }
    Timer { id: start; interval: 500; onTriggered: harness.ready=true }
    TestCase {
        id: tests
        name: "YeneratorKeyboard"
        when: harness.ready
        function require(condition, label) {
            if (!condition) { console.error("FAIL", label); throw new Error(label || "assertion failed") }
        }
        function equal(actual, expected, label) {
            if (actual !== expected) { console.error("FAIL", label, actual, expected); throw new Error(label || "comparison failed") }
        }
        function test_interactions() {
            console.log("TEST_STARTED")
            var content = harness.popup.contentItem[0]
            var inss = findChild(content, "inssRow")
            var bsn = findChild(content, "bsnRow")
            var iban = findChild(content, "ibanRow")
            var email = findChild(content, "emailRow")
            var picker = findChild(content, "countryPicker")
            require(inss && bsn && iban && email && picker)
            content.forceActiveFocus()
            console.log("FOCUS",content.activeFocus)
            var oldInss = widget.inss.raw
            var oldIban = widget.iban.raw
            var oldEmail = widget.email.raw
            keyClick(Qt.Key_R)
            console.log("R_SENT")
            require(widget.inss.raw !== oldInss, "R regenerates INSS")
            require(widget.iban.raw !== oldIban, "R regenerates IBAN")
            require(widget.email.raw !== oldEmail, "R regenerates Email")
            mouseMove(iban, 15, 15)
            equal(widget.selectedKind, "IBAN", "hover selects IBAN")
            keyClick(Qt.Key_C)
            equal(harness.capturedValue, widget.iban.raw, "C copies raw IBAN")
            equal(harness.capturedKind, "IBAN", "captured copy kind")
            keyClick(Qt.Key_Up)
            equal(widget.selectedKind, "INSS", "up selects INSS")
            keyClick(Qt.Key_C)
            equal(harness.capturedValue, widget.inss.raw, "C copies selected INSS")
            oldIban = widget.iban.raw
            keyClick(Qt.Key_R, Qt.ControlModifier)
            equal(widget.iban.raw, oldIban, "Ctrl+R is not intercepted")
            picker.open()
            wait(100)
            keyClick(Qt.Key_R)
            equal(widget.iban.raw, oldIban, "R is suspended in country menu")
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Return)
            equal(widget.country, "NL", "Dropdown keyboard selection")
            equal(widget.iban.country, "NL")
            equal(widget.inss, null, "No Belgian INSS for NL")
            equal(inss.visible, false)
            equal(bsn.visible, true)
            require(widget.bsn !== null)
            equal(widget.selectedKind, "BSN", "NL selection target")
            content.forceActiveFocus()
            keyClick(Qt.Key_C)
            equal(harness.capturedKind, "BSN", "captured copy kind")
            equal(harness.capturedValue, widget.bsn.raw)
            var oldBsn = widget.bsn.raw
            keyClick(Qt.Key_R)
            require(widget.bsn.raw !== oldBsn, "R regenerates BSN")
            keyClick(Qt.Key_Down)
            equal(widget.selectedKind, "IBAN")
            keyClick(Qt.Key_Up)
            equal(widget.selectedKind, "BSN")
            keyClick(Qt.Key_Tab)
            require(iban.activeFocus, "Tab from BSN to IBAN")
            keyClick(Qt.Key_Backtab)
            require(bsn.activeFocus, "Shift+Tab returns to BSN")
            widget.selectCountry("DE")
            equal(bsn.visible, false)
            equal(widget.bsn, null)
            equal(widget.selectedKind, "IBAN", "DE starts with IBAN")
            require(email.visible, "Email is available for DE")
            iban.forceActiveFocus()
            keyClick(Qt.Key_Down)
            equal(widget.selectedKind, "Email", "Down selects Email")
            keyClick(Qt.Key_C)
            equal(harness.capturedKind, "Email")
            equal(harness.capturedValue, widget.email.raw, "Email copy preserves punctuation")
            keyClick(Qt.Key_Backtab)
            require(iban.activeFocus, "Shift+Tab from Email to IBAN")
            keyClick(Qt.Key_Tab)
            require(email.activeFocus, "Tab from IBAN to Email")
            widget.selectCountry("BE")
            equal(bsn.visible, false)
            equal(widget.bsn, null)
            equal(inss.visible, true)
            require(widget.inss !== null)
            inss.forceActiveFocus()
            keyClick(Qt.Key_Tab)
            require(iban.activeFocus, "Tab navigates between rows")
            keyClick(Qt.Key_Backtab)
            require(inss.activeFocus, "Shift+Tab navigates back")
            picker.open()
            wait(100)
            keyClick(Qt.Key_Escape)
            equal(picker.popupOpen, false)
            require(widget.opened, "Escape closes dropdown first")
            content.forceActiveFocus()
            keyClick(Qt.Key_Escape)
            require(!widget.opened, "Escape closes panel")
            console.log("YENERATOR_KEYBOARD_OK")
        }
        function cleanupTestCase() { console.log("TEST_ENDED"); Qt.quit() }
    }
    Timer { interval: 12000; running: true; onTriggered: { console.error("TEST_TIMEOUT"); Qt.quit() } }
}
