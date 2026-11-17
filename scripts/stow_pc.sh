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

for profile in common linux pc
    stow -d $STOW_DIR/$profile -t $HOME -v home --adopt --no-folding
end

# Stow only links unit files in ~/.config/systemd/user; enablement lives in
# *.wants/ and has to be recreated on a fresh machine.
if command -q systemctl
    echo "Enabling user units"
    systemctl --user enable darkman.service opencode.service
end
