#!/opt/homebrew/bin/fish

set SCRIPT_DIR (dirname (realpath (status -f)))
set STOW_DIR (dirname $SCRIPT_DIR)

echo "Stowing common configs"
stow --adopt -d $STOW_DIR/common -t $HOME -v home

echo "Stowing mac configs"
stow --adopt -d $STOW_DIR/macbook -t $HOME -v home
