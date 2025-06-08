#!/bin/fish

set SCRIPT_DIR (dirname (realpath (status -f)))
set STOW_DIR (dirname $SCRIPT_DIR)

stow --adopt -d $STOW_DIR -t $HOME -v home
