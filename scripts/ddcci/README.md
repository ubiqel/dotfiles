# ddcci-backlight Waybar setup

Uses the `ddcci-backlight` kernel driver to expose external monitor brightness
as standard Linux backlight devices, controlled from Waybar via `brightnessctl`.
Much faster and more responsive than calling `ddcutil` on every scroll event.

## Files

| File | Purpose |
|---|---|---|
| `bootstrap.sh` | One-shot setup for a fresh Arch Linux system |
| `verify-mapping.sh` | Check that Waybar's `ddcci*` device names match the hardware |
| `ddcci-setup.sh` | Kernel module loader + manual I²C device probing (run as root) |
| `ddcci.service` | systemd service to run `ddcci-setup` at boot |
| `ddcci-resume.service` | systemd service to re-probe after suspend/resume |
| `ddcci.modules.conf` | `/etc/modules-load.d/` snippet |

## Why manual probing is needed

On kernel 6.8+ the `ddcci` driver can no longer auto-probe displays. The setup
script manually instantiates a DDC/CI client at address `0x37` on every display
I²C adapter.

## Stale I²C clients

Some monitors can leave a stale I²C client at `0x37` without a bound backlight
device, usually after an aborted probe. The kernel then returns `EBUSY` on any
new probe attempt, so `ddcci-setup.sh` detects and removes those stale clients
before re-probing.

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
is not responding, verify the device mapping:

```bash
./scripts/ddcci/verify-mapping.sh
```

### Fix mapping automatically

If devices are missing or mapped incorrectly, run with `--fix`:

```bash
./scripts/ddcci/verify-mapping.sh --fix
```

This will:

1. Recreate any missing `ddcci*` backlight devices (cleaning stale clients if
   needed) by running `ddcci-setup.sh`.
2. Rewrite device names in `~/.config/waybar/config.jsonc` if they changed.
3. Reload Waybar.

### Cycle presets in Waybar

- Scroll up/down: ±5%
- Left click: cycle 0% → 50% → 100% → 0%

## Troubleshooting

- If `/sys/class/backlight/` has no `ddcci*` devices, check that the service
  ran successfully: `systemctl status ddcci.service`
- If `dmesg` shows `Failed to register i2c client ddcci at 0x37 (-16)`, run
  `verify-mapping.sh --fix` to clean up stale clients.
- If Waybar modules are empty, run Waybar in debug mode to see module errors:
  `waybar -l debug`
