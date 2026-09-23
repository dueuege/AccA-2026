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
- AccA dashboard shows "ACC Daemon is Running" and reads the switch and limits from ACC

## Charging switch in use: `battery/charge_control_limit`

```
chargingSwitch=(battery/charge_control_limit 0 battery/charge_control_limit_max --)
```

The auto pick, `battery/device/force_charger_suspend`, is **not reliable** on this phone, so it
was replaced. Measured by writing each switch "off" by hand (ACC stopped, 10 s settle, cable in,
battery at 97%):

| Switch (off) | kernel `status` | Android status | battery current |
|---|---|---|---|
| `battery/device/force_charger_suspend` = 1 | Charging | 2 (charging) | **+478 mA, still charging** |
| `battery/charge_control_limit` = max (8) | **Not charging** | **4 (not charging)** | −6 mA (idle) |
| `battery/current_max` = 0 | **Not charging** | **4 (not charging)** | −6 mA (idle) |
| `charger/input_current_limit` = 0 | Charging | 2 | ~0 |
| `usb/input_current_limit` = 0 | Charging | 2 | ~0 |
| `usb/device/force_charger_suspend` = 1 | Charging | 2 | −196 mA |

`charge_control_limit` truly idles the battery (the phone runs from the charger), and with it the
Motorola driver reports "Not charging". Most other switches leave the kernel saying "Charging", so
Android's UI shows charging even when it isn't. `battery/current_max` is the fallback.

When changing away from `force_charger_suspend`, set it back to 0 by hand
(`echo 0 > /sys/class/power_supply/battery/device/force_charger_suspend`); ACC does not reset a
switch it no longer manages.

The status-bar lightning bolt stays while the cable is in: stock Android draws it whenever the
phone is plugged in. Android's battery status (`dumpsys battery`) is the real indicator.

## Switch test (`acc -t`, 2026-09-23, on USB/PC power)

Full output: [`acc-t_output-milanf_2026-09-23.log`](acc-t_output-milanf_2026-09-23.log).

Working, **battery idle** (phone runs from the charger, battery neither charges nor drains):

- `battery/charge_control_limit 0 battery/charge_control_limit_max`
- `battery/current_max 3000000 0`
- `battery/current_max 3000000 10000`
- `charger/input_current_limit 3000000 0`
- `usb/input_current_limit 500000 0`

Working, charging cut (battery supplies the phone):

- `battery/device/force_charger_suspend 0 1` (passed here, but did not hold later; see above)
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

To set the switch again (e.g. if AccA re-locks a different one):

```
su -c '/dev/acc -s s="battery/charge_control_limit 0 battery/charge_control_limit_max --"'
```

`config.txt` is the phone's working ACC config (pause 60%, resume 35%, `charge_control_limit`).
