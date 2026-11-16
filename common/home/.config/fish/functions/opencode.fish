function opencode --wraps opencode --description 'Pin opencode to the local always-on server'
    command opencode --server http://127.0.0.1:4096 $argv
end
