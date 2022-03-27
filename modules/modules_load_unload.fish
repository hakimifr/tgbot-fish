#!/bin/fish

set -g __module_name "Modules load and unload"
set -g __module_description "To be used to load and unload modules from telegram"
set -g __module_version 69
set -g __module_functions modules_load_unload
set -g __module_help_message "Irrelevant to other than bot owner\. Available commands:
`.load modulepath/modulename.fish` \-\> Load a module from the path given\.
`.unload modulebasename` \-\> Unload a loaded module\."

function modules_load_unload -d "Module: modules/modules_load_unload" --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.unload*'
            if not is_botowner
                err_not_botowner
                return
            end

            if test -z (string replace -r '^.unload' '' $ret_lowered_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Give module name to unload please"
                return
            end

            set -l module_trimmed (string replace -r '^.unload ' '' $ret_lowered_msg_text)
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Unloading $module_trimmed"
            __module_unload $module_trimmed
            if test $status -eq 2
                tg --editmsg "$ret_chat_id" "$sent_msg_id" "Failed to unload $module_trimmed, it does not exist."
            else
                tg --editmsg "$ret_chat_id" "$sent_msg_id" "Module $module_trimmed unloaded"
            end
        case '.load*'
            if not is_botowner
                err_not_botowner
                return
            end

            if test -z (string replace -r '^.load' '' $ret_lowered_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Give module name to load please"
                return
            end

            set -l module_trimmed (string replace -r '^.load ' '' $ret_lowered_msg_text)
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Loading module $module_trimmed"
            __module_load $module_trimmed
            if test $status -eq 2
                tg --editmsg "$ret_chat_id" "$sent_msg_id" "Failed to load $module_trimmed, file does not exist."
            else if test $status -eq 3
                tg --editmsg "$ret_chat_id" "$sent_msg_id" "Failed to load $module_trimmed, one or more property isn't set by that module."
            else if test $status -eq 4
                tg --editmsg "$ret_chat_id" "$sent_msg_id" "Failed to load $module_trimmed, fatal: conflicting events/functions with other module."
            else
                tg --editmsg "$ret_chat_id" "$sent_msg_id" "Module $module_trimmed loaded"
            end
    end
end
