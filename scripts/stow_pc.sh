#!/bin/fish

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
