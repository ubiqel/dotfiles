function lightctl
    function main
        switch $argv[1]
            case get
                ddcutil -d 1 getvcp 10
                ddcutil -d 2 getvcp 10
            case high
                ddcutil -d 1 setvcp 10 100
                ddcutil -d 2 setvcp 10 100
            case low
                ddcutil -d 1 setvcp 10 20
                ddcutil -d 2 setvcp 10 0
            case reset
                ddcutil -d 1 setvcp 10 60
                ddcutil -d 2 setvcp 10 50
            case inc
                inc_brightness 20
            case dec
                dec_brightness 20
            case 'help' '*'
                echo 'Usage: lightctl [get|high|low|reset|inc|dec|help]'
        end
    end

    function inc_brightness
        for monitor in 1 2
            set current_brightness (get_current_brightness $monitor)
            echo $monitor "current: " $current_brightness

            # Handling corner cases
            if test $current_brightness -ge 100
                continue
            end

            set new_brightness (math $current_brightness + $argv[1])
            echo $monitor "new: " $new_brightness
            if test $new_brightness -gt 100
                set new_brightness 100
            end
            ddcutil -d $monitor setvcp 10 $new_brightness
        end
    end

    function dec_brightness
        for monitor in 1 2
            set current_brightness (get_current_brightness $monitor)
            echo "current: " $current_brightness

            if test $current_brightness -le 0
                continue
            end

            set new_brightness (math $current_brightness - $argv[1])
            echo "new: " $new_brightness
            if test $new_brightness -lt 0
                set new_brightness 0
            end

            ddcutil -d $monitor setvcp 10 $new_brightness
        end
    end

    function get_current_brightness
        ddcutil -d $argv[1] getvcp 10 | string match -r '\d+(?=,)'
    end

    function check_module
        if test (lsmod | grep i2c_dev)
            return
        end

        modprobe i2c-dev
        if test $status -ne 0
            echo "Error: Failed to load the i2c_dev module."
            return
        end
    end

    check_module
    if test $status -ne 0
        return
    end

    main $argv
end
