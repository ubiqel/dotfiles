function e
    set -l env_file .env
    if test -n "$argv"
        if not test -f "$argv"
            echo "File $argv does not exist"
            return 1
        end

        set env_file "$argv"
    end

    for line in (cat $env_file | grep -v '^#')
        if test -z "$line"
            continue
        end

        set -gx (echo $line | cut -d '=' -f 1) (echo $line | cut -d '=' -f 2-)
    end
end
