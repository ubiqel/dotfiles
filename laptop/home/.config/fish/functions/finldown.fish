function finldown --wraps='nmcli connection down finl' --description 'alias finldown=nmcli connection down finl'
  nmcli connection down finl $argv
        
end
