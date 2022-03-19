#!/bin/fish

set -g __module_name "Modules info (modules_info.fish)"
set -g __module_description "Module to view an invidual module info."
set -g __module_version 69
set -g __module_events "info"
set -g __module_functions "module_info"

function module_info --on-event 'info'
    switch $ret_lowered_msg_text
        case '.modinfo*'
            if test -z (string replace -r '^.modinfo' '' $ret_lowered_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Give a module to view info please"
                return
            end

            module_info::fetch (string replace -r '^.modinfo ' '' $ret_lowered_msg_text)
            if test $status -eq 2
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Module does not exist (or maybe not loaded?)"
            else
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "\
Module name: $__module_name
Module description: $__module_description
Module version: $__module_version
Module events: $__module_events
Module functions: $__module_functions
"
            end
        case '.lsmod'
            set -l loaded_mod (find metadata -type f -iname '*.fish')
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "\
Loaded modules:
$(for mod in $loaded_mod; basename $mod; end)
"
            module_info::cleanup
    end
end

function module_info::fetch
    if test -z $argv[1]
        return 1 # No filename passed, although this should've been rectified earlier
    end

    if not test -f metadata/(basename $argv[1])
        return 2 # Does not exist
    end

    source metadata/(basename $argv[1])
    return 0
end

function module_info::cleanup
    set -ge __module_name
    set -ge __module_load
    set -ge __module_events
    set -ge __module_functions
    set -ge __module_description
end
