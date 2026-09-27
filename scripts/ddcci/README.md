# ddcci-backlight Waybar setup

Uses the `ddcci-backlight` kernel driver to expose external monitor brightness
as standard Linux backlight devices, controlled from Waybar via `brightnessctl`.
Much faster and more responsive than calling `ddcutil` on every scroll event.

## Files

| File | Purpose |
|---|---|
| `bootstrap.sh` | One-shot setup for a fresh Arch Linux system |
| `verify-mapping.sh` | Check (and with `--fix`, repair) that Waybar's monitors resolve to live devices |
| `ddcci-setup.sh` | Kernel module loader + manual I²C device probing (run as root) |
| `ddcci.service` | systemd oneshot that runs `ddcci-setup` |
| `ddcci.timer` | Triggers `ddcci.service` shortly after boot |
| `ddcci-resume.service` | systemd service to re-probe after suspend/resume |
| `ddcci.modules.conf` | `/etc/modules-load.d/` snippet |
| `99-ddcci.rules` | udev rule that re-probes when a DRM connector goes connected |

## Why manual probing is needed

On kernel 6.8+ the `ddcci` driver can no longer auto-probe displays. The setup
script manually instantiates a DDC/CI client at address `0x37` on every display
I²C adapter.

## Why the probe is delayed

Displays are not DDC/CI-ready when the machine first boots: the probe used to
run during early boot and `ddcutil detect` returned no displays, so no backlight
devices were created and the service still reported success. The probe is now
triggered in three ways, all after the graphics stack is up:

1. `ddcci.timer` fires `ddcci.service` ~30 s after boot, and the service is
   ordered `After=graphical.target`.
2. `99-ddcci.rules` re-runs it whenever a DRM connector reports a hotplug
   (monitor powered on, cable re-plugged).
3. `ddcci-resume.service` re-runs it after suspend/hibernate.

`ddcci-setup.sh` also waits (up to `DDCCI_WAIT_SECONDS`, default 90 s) for
`ddcutil` to report a connected display, and exits non-zero if it ultimately
fails, so the failure is visible instead of silent. A `flock` on
`/run/ddcci-setup.lock` keeps the boot timer, hotplug and resume triggers from
probing concurrently.

### ddcutil needs a usable HOME

`ddcutil` 3.x aborts initialization when it cannot determine its dynamic-sleep
stats file ("Unable to determine dynamic sleep stats file name"), which happens
under systemd because system services have no `HOME`. The setup script passes
`--disable-dynamic-sleep` to `detect` and the units set `Environment=HOME=/root`
so probing works from systemd as well as from an interactive shell.

## Stable device names

The `ddcci` backlight device name embeds the I²C bus number (`ddcci4`,
`ddcci5`, …), which can change between boots. Instead of hardcoding those names
in the Waybar config, the config refers to stable roles (`M1`, `M2`) defined in
`~/.config/waybar/ddcci-monitors.conf`:

```
M1=GBT:M27Q P:23133B000026
M2=XMI:Mi Monitor:7041110045904
```

Each identity is the `Monitor:` field from `ddcutil detect --brief`
(`MFG:MODEL:SERIAL`). `waybar-ddcci` resolves a role to the current `ddcciN`
on demand (and caches the result, invalidating it if the device disappears), so
the Waybar config never needs to be rewritten when bus numbers shift.

## Stale I²C clients and driver state

Some monitors can leave a stale I²C client at `0x37` without a bound backlight
device, usually after an aborted probe. The kernel then returns `EBUSY` on any
new probe attempt, so `ddcci-setup.sh` detects and removes those stale clients
before re-probing.

A few monitors (e.g. Gigabyte M27Q P) return a malformed DDC/CI capability
string. The `ddcci` driver creates an internal device reference but fails to
register the backlight device. Later probes then fail with `EEXIST` because the
stale internal reference is still present. When normal probing fails,
`ddcci-setup.sh` unloads and reloads the `ddcci` modules to clear that state,
then re-probes.

## Usage

### Fresh system

Run `stow_pc.sh`, which calls the bootstrap script after deploying dotfiles:

```bash
./scripts/stow_pc.sh
```

Or run the bootstrap directly:

```bash
./scripts/ddcci/bootstrap.sh
```

You will be prompted for `sudo` to install system files and enable services.

### Check mapping

After hardware changes (new GPU, different cable/ports) or if a Waybar module
is not responding, verify the mapping:

```bash
./scripts/ddcci/verify-mapping.sh
```

### Fix mapping automatically

If devices are missing or a role cannot be resolved, run with `--fix`:

```bash
./scripts/ddcci/verify-mapping.sh --fix
```

This will:

1. Recreate any missing `ddcci*` backlight devices (cleaning stale clients if
   needed) by running `ddcci-setup.sh`.
2. Re-check that every Waybar role resolves to a live device.
3. Reload Waybar.

### Add a monitor / change ports

The roles are keyed by EDID identity, so moving a cable does not break the
mapping. For a brand new monitor, list the identities and add a role:

```bash
ddcutil detect --brief | grep Monitor:
```

### Cycle presets in Waybar

- Scroll up/down: ±5%
- Left click: cycle 0% → 50% → 100% → 0%

## Troubleshooting

- If `/sys/class/backlight/` has no `ddcci*` devices, check the service:
  `systemctl status ddcci.service ddcci.timer`
- If `dmesg` shows `Failed to register i2c client ddcci at 0x37 (-16)`, run
  `verify-mapping.sh --fix` to clean up stale clients.
- If Waybar modules are empty, run Waybar in debug mode to see module errors:
  `waybar -l debug`
- To resolve a single role by hand: `waybar-ddcci resolve M1`.
