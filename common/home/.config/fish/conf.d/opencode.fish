if test -r ~/.config/opencode/server.env
    for line in (cat ~/.config/opencode/server.env)
        if string match -qr '^OPENCODE_PASSWORD=' -- $line
            set -gx OPENCODE_PASSWORD (string replace 'OPENCODE_PASSWORD=' '' -- $line)
        end
    end
end
