#!/bin/fish

function modules_load_unload -d "Module: modules/modules_load_unload"
    switch $ret_lowered_msg_text
        case '.unload*'
            if not is_botowner
                err_not_botowner
                return
            end
            set -l module_name (string replace -r '^.unload ' '' $ret_lowered_msg_text)
            set -l module_name (string replace -r '^modules/' '' $module_name)
            set -l module_name (string replace -r '.fish$' '' $module_name)
            pr_debug "modules_load_unload" "$module_name"
            functions $module_name || begin
                # pr err
                tg --replymsg $ret_chat_id $ret_msg_id "Failed to unload module, you sure you typed it correctly?"
                return
            end
            set -e $module_name
            tg --replymsg $ret_chat_id $ret_msg_id "Module $module_name unloaded"

            # Remove from loaded modules
            set -l count 1
            for loaded_module in $loaded_modules
                if test "modules/$module_name.fish" = $loaded_module
                    set -ge loaded_modules[$count]
                end
                set count (math $count + 1)
            end
        case '.load*'
            if not is_botowner
                err_not_botowner
            end
            set -l module_name (string replace -r '^.load ' '' $ret_lowered_msg_text)
            for module in $loaded_modules
                if test "$module_name" = module
                    set -l load_error true
                end
            end
            if test "$load_error" = true
                tg --replymsg "That module is already loaded, try unloading it first"
                set -le load_error
            else
                source $module_name || begin
                    tg --replymsg $ret_chat_id $ret_msg_id "Failed to load module, are you sure you typed it right?"
                    return
                end
                set -ga loaded_modules $module_name
                tg --replymsg $ret_chat_id $ret_msg_id "Module $module_name loaded"
        end
    end
end
