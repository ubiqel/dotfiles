function finlup --wraps='nmcli connection up finl' --description 'alias finlup=nmcli connection up finl'
  nmcli connection up finl $argv
end
