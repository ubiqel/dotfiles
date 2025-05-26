# read .env file in bash format and set environmental variable values in fish; also ignore comments optional
# argument is the path to the .env file usage: `e /path/to/.env`
function e
    set -l env_file .env
    if test -n "$argv"
        # check if file exists
        if not test -f "$argv"
            echo "File $argv does not exist"
            return 1
        end

        set env_file "$argv"
    end

    for line in (cat $env_file | grep -v '^#')
        # handle empty lines
        if test -z "$line"
            continue
        end

        set -gx (echo $line | cut -d '=' -f 1) (echo $line | cut -d '=' -f 2-)
    end
end
