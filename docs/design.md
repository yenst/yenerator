# Yenerator · native panel design

A compact Omarchy utility: dice hero, two generated values, a country selector,
and inline refresh/copy actions. The panel uses the same 380 px base width and
14 px section rhythm as the native network, audio, power, and Bluetooth panels.
All dimensions, typography, colors, borders, hover fills, and focus rings follow
Omarchy tokens and the current bar theme.

Generated identifiers are readable results instead of input fields. The INSS
birth date and sex sit underneath as secondary metadata. The IBAN country is a
compact native dropdown beside its section label. Long IBANs wrap at group
boundaries; copying always uses the original raw value. A brief checkmark and
single-line status confirm copying. “MOCK DATA” remains visible in the hero.

## Native references

Read-only visual references on the installed system:

- `/usr/share/omarchy/shell/plugins/panels/network/Panel.qml`: compact hero,
  section headers, separators, and inline row actions.
- `/usr/share/omarchy/shell/plugins/panels/audio/Panel.qml`: flat content,
  restrained hierarchy, and token-based spacing.
- `/usr/share/omarchy/shell/plugins/panels/power/Panel.qml`: 380 px panel and
  icon/title/uppercase-status hero.
- `/usr/share/omarchy/shell/plugins/panels/bluetooth/Panel.qml`: secondary row
  metadata and trailing action buttons.

The implementation directly reuses `Ui.Panel`, `Ui.KeyboardPanel`,
`Ui.PanelHero`, `Ui.PanelSectionHeader`, `Ui.PanelSeparator`,
`Ui.PanelActionButton`, and `Ui.Dropdown` from
`/usr/share/omarchy/shell/Ui/`. No packaged shell files are changed.

## Icon and interaction

The default is Nerd Font Material Design `dice-multiple-outline` (U+F1156).
`shuffle` (U+F049D) is an alternative. The panel's `icon` setting controls both
the bar glyph and hero, keeping them consistent.

Tab/Shift+Tab walk the refresh, copy, and country controls. Enter or Space
activates actions; the native dropdown supports arrows and Enter. Escape closes
the dropdown first, then the panel. Native button focus rings and accessible
action names identify every icon control. Outside-click dismissal and bar
positioning remain owned by `Ui.KeyboardPanel`.

## Preview and validation

![Rendered Yenerator panel](design.png)

![French IBAN layout](design-fr.png)

The panel was rendered in a temporary Quickshell process with the current Forest
Night theme and compared side by side with the installed native audio panel.
Belgian and French result layouts have no clipping. Country selection updates the
IBAN, the dropdown opens, and closing the panel closes the dropdown. The generator
tests, Omarchy manifest validation, and QML parser check pass.

Keyboard traversal, actual clipboard contents, and additional display scales
still need interactive verification.
