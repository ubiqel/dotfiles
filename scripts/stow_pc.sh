#!/bin/fish
# Stow the profiles for this machine (common, linux, pc).
#
# --adopt applies to every profile, not just pc: if a target file already
# exists in $HOME, stow moves it into the stow package before linking, so the
# repo silently picks up the host's version for common and linux as well.
# Check `git status`/`git diff` afterwards and revert anything unintended
# before committing.
set SCRIPT_DIR (dirname (realpath (status -f)))
set STOW_DIR (dirname $SCRIPT_DIR)

# opencode rewrites its own config files (cli.json) via write+rename, which
# replaces per-file symlinks with real files. So it gets one directory symlink
# instead, and is excluded from stow here. --no-folding stays for everything
# else because common/linux/pc share most config dirs.
set -l ignore_opencode '^\.config/opencode($|/)'

for profile in common linux pc
    stow -d $STOW_DIR/$profile -t $HOME -v home --adopt --no-folding --ignore=$ignore_opencode
end

set -l opencode_src $STOW_DIR/common/home/.config/opencode
set -l opencode_dst $HOME/.config/opencode
if test -L $opencode_dst
    # already linked
else if test -e $opencode_dst
    echo "opencode: $opencode_dst exists and is not a symlink." >&2
    echo "It should only hold links into this repo — remove it and re-run." >&2
    exit 1
else
    ln -s (realpath --relative-to=$HOME/.config $opencode_src) $opencode_dst
end

# Stow only links unit files in ~/.config/systemd/user; enablement lives in
# *.wants/ and has to be recreated on a fresh machine.
if command -q systemctl
    echo "Enabling user units"
    systemctl --user enable darkman.service opencode.service
end
