#!/bin/fish

set SCRIPT_DIR (dirname (realpath (status -f)))
set STOW_DIR (dirname $SCRIPT_DIR)

stow -d $STOW_DIR/common -t $HOME -v home --adopt --no-folding
stow -d $STOW_DIR/linux -t $HOME -v home --adopt --no-folding
stow -d $STOW_DIR/pc -t $HOME -v home --adopt --no-folding

# Stow only links unit files in ~/.config/systemd/user; enablement lives in
# *.wants/ and has to be recreated on a fresh machine.
if command -q systemctl
    echo "Enabling user units"
    systemctl --user enable darkman.service opencode.service
end
