#!/bin/fish

set SCRIPT_DIR (dirname (realpath (status -f)))
set STOW_DIR (dirname $SCRIPT_DIR)

stow  -d $STOW_DIR/common -t $HOME -v home --adopt
stow -d $STOW_DIR/pc -t $HOME -v home --adopt
