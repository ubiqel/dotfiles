function fish_user_key_bindings
    for mode in insert default visual
        bind -M $mode \cf forward-char
    end

    bind Y fish_clipboard_copy
    bind p fish_clipboard_paste
end
