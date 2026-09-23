# AccA-2026

Working set of **ACC** (Advanced Charging Controller, the root daemon that stops charging at a set
level) and **AccA** (its Android front-end app), pinned to versions that are verified working on a
2026 phone running Android 16 with Magisk 30.7.

## Layout

| Path | What | Source |
|---|---|---|
| `acc/` | ACC source, **v2025.5.18-6.5.1-rc24** (versionCode 202505333) | [seyedehsanhadi/acc](https://github.com/seyedehsanhadi/acc) tag `v2025.5.18-6.5.1-rc24`, commit `c97c768` |
| `AccA/` | AccA app source, **2.0.1-rc23** (versionCode 223) | [seyedehsanhadi/AccA](https://github.com/seyedehsanhadi/AccA) tag `v2.0.1-rc23`, commit `1061a9a` |
| `upstream/acc-vr25-v2025.5.18-dev/` | Last upstream ACC by VR-25 (kept for reference; not installed) | [VR-25/acc](https://github.com/VR-25/acc) `v2025.5.18-dev` |
| `dist/` | Release binaries matching the two sources above, with `SHA256SUMS` | GitHub releases of the two forks |
| `scripts/install-acc.sh` | Installs `dist/acc_*.tgz` on a phone over adb (optionally the APK too) | this repo |
| `devices/` | Per-phone notes: switch test results, working config | this repo |

`acc/` and `AccA/` are snapshots of the tagged fork sources (`git archive` of each tag), unmodified
apart from line endings: a few upstream `.txt` files were stored with CRLF and are LF here.

## Why these versions

- VR-25's original ACC stopped at `v2025.5.18-dev` (May 2025) and the F-Droid AccA still bundles ACC
  **v2021.8.31**. On Android 16 that 2021 ACC finds **no charging switch**, so `accd` exits with code 7
  and never limits charging.
- The seyedehsanhadi forks are the maintained continuation. AccA 2.0.1-rc23 **no longer bundles ACC**;
  its changelog says it "pairs with ACC v2025.5.18-6.5.1-rc24. Install both." Installing only the app
  over an old ACC leaves the old, broken daemon in place, which is what happened here.

## Install on a phone

Requirements: root (Magisk, KernelSU or APatch), USB debugging, `adb` on PATH.

```bash
scripts/install-acc.sh -s <serial> --apk
```

Then open AccA. No reboot is needed; after a reboot `acc` is also on the root PATH (before that, use
`/dev/acc`).

Manual equivalent: push `dist/acc_*.tgz` and `acc/install-tarball.sh` into the same directory on the
phone and run `su -c 'sh install-tarball.sh acc'` there.

> **Pitfall:** do not stage the files in `/data/local/tmp/acc-…` or `/data/local/tmp/acc_…`. ACC's
> `uninstall.sh`, which the installer runs to remove the previous version, deletes
> `/data/local/tmp/acc[-_]*`, including the tarball being installed, and the install aborts with
> `cp: can't stat …/install/*`.

## Useful commands (as root)

```
acc -i          battery info
acc -s          show config
acc -t          test every charging switch (log goes to /sdcard/Download/acc-t_output-*.log)
acc -s s="<ctrl-file> <on> <off> --"   pin a charging switch
acc -b          roll back to the previously installed ACC
```

## Licenses

ACC and AccA are GPLv3+; see `acc/License.md` and `AccA/LICENSE`.
