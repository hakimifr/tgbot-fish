#!/bin/fish

set -g __module_name "Modules info (modules_info.fish)"
set -g __module_description "Module to view an invidual module info."
set -g __module_version 69
set -g __module_functions module_info
set -g __module_help_message "$(string replace '.' '\\.' $__module_description)
`.modinfo modulename` \-\> View module info\.
`.modcat modulename` \-\> View a module content\."

function module_info --on-event info
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
Module help message: Use .modhelp modulename to view individual module help message.
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
        case '.modhelp*'
            if test -z (string replace -r '^.modhelp' '' $ret_lowered_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Give a module to view help please"
                return
            end

            module_info::fetch (string replace -r '^.modhelp ' '' $ret_lowered_msg_text)
            if test $status -eq 2
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Module does not exist (or maybe not loaded?)"
            else
                set -l module_name (string replace -r '^.modhelp ' '' $ret_lowered_msg_text)
                set -l module_name (string replace -a '-' '\\-' $module_name)
                set -l module_name (string replace -a '_' '\\_' $module_name)
                set -l module_name (string replace -a '.' '\\.' $module_name)
                set -l error_code (curl -s "$API/sendMessage" -d "chat_id=$ret_chat_id" -d "reply_to_message_id=$ret_msg_id" -d "parse_mode=MarkdownV2" -d "text=Help for module $module_name:
$__module_help_message" | jq '.error_code')
                pr_debug modules_info "error_code: $error_code"
                pr_debug modules_info "module_name: $module_name"
                pr_debug modules_info "module help message: $__module_help_message"
                if test "$error_code" != null -a "$error_code" = 400
                    tg --replymsg "$ret_chat_id" "$ret_msg_id" "Telegram failed to parse markdown. Module author need to fix the module help message."
                end
            end
            module_info::cleanup
        case '.modcat*'
            if test -z (string replace -r '^.modcat' '' $ret_lowered_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Give a module to cat please"
                return
            end

            if not test -f modules/(string replace -r '^.modcat ' '' $ret_lowered_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Module does not exist (or maybe not loaded?)"
            else
                set -l termbin_link (nc termbin.com 9999 < modules/(string replace -r '^.modcat ' '' $ret_lowered_msg_text))
                if test $status -ne 0
                    tg --replymsg "$ret_chat_id" "$ret_msg_id" "An error occured"
                else
                    tg --replymsg "$ret_chat_id" "$ret_msg_id" "$termbin_link"
                end
            end
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
    set -ge __module_functions
    set -ge __module_description
    set -ge __module_help_message
end
