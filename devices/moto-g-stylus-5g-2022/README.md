# moto g stylus 5G (2022) — `milanf`

| | |
|---|---|
| SoC | Snapdragon 695 (`holi`) |
| OS | Android 16 (SDK 36, build `BP4A.251205.006`) |
| Root | Magisk 30.7 |
| ACC | v2025.5.18-6.5.1-rc24 (202505333), installed 2026-09-23 |
| AccA | 2.0.1-rc23 (223) |

## What was wrong

ACC **v2021.8.31** (installed by an older AccA) was on the phone. It found no charging switch
(`/dev/.vr25/acc/ch-switches` was empty), so `accd` exited with code 7 and the phone charged to
100%. AccA 2.0.1-rc23 had been installed on top, but it no longer bundles ACC, so the old daemon
stayed.

## Fix

Installed ACC rc24 with `scripts/install-acc.sh`. The existing config (pause 60%, resume 35%) was
migrated. Right after install:

- `accd` running; auto-selected switch `battery/device/force_charger_suspend 0 1`
- at 96% (above the 60% pause level): switch engaged, charger input 0 mA, battery current about 0
  (ACC classifies it as `bypass`); the kernel `status` still says "Charging", which is a stale
  label, not real charging
- AccA dashboard shows "ACC Daemon is Running" and reads the switch and limits from ACC

## Switch test (`acc -t`, 2026-09-23, on USB/PC power)

Full output: [`acc-t_output-milanf_2026-09-23.log`](acc-t_output-milanf_2026-09-23.log).

Working, **battery idle** (phone runs from the charger, battery neither charges nor drains):

- `battery/charge_control_limit 0 battery/charge_control_limit_max`
- `battery/current_max 3000000 0`
- `battery/current_max 3000000 10000`
- `charger/input_current_limit 3000000 0`
- `usb/input_current_limit 500000 0`

Working, charging cut (battery supplies the phone):

- `battery/device/force_charger_suspend 0 1` (ACC's current auto pick)
- `usb/device/force_charger_suspend 0 1`
- `dc/current_max 3000000 0`, `pc_port/current_max 3000000 0`, `usb/current_max 3000000 0`
- `battery/constant_charge_current_max 5000000 0`
- `charger/input_current_limit 500000 10000`, `usb/current_max 500000 10000`,
  `usb/input_current_limit 500000 10000`

Not working: `battery/constant_charge_current*` (other values), `battery/input_current_limit`,
`dc/input_current_limit`, `usb/input_current_limit 3000000 0`, `charger/input_current_limit 500000 0`,
`pc_port/current_max 500000 *`, `usb/current_max 500000 0`, `battery/voltage_max`.

The test ran on a PC USB port (about 0.5 A). Results can differ on a fast (USB-PD) charger; re-run
`acc -t` or AccA's "Find my charging switch" on the charger you normally use.

To pin the idle-mode switch instead of the auto pick (useful if the phone stays plugged in a lot):

```
su -c 'acc -s s="battery/charge_control_limit 0 battery/charge_control_limit_max --"'
```

`config.txt` is the phone's ACC config as of this install.
