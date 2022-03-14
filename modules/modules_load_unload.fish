#!/bin/fish

set -ga modules_events "modules_management"
function modules_load_unload -d "Module: modules/modules_load_unload" --on-event 'modules_management'
    switch $ret_lowered_msg_text
        case '.unload*'
            if not is_botowner
                err_not_botowner
                return
            end

            set -l module_name (string replace -r '^.unload ' '' $ret_msg_text)
            set -l module_exist false

            # Do not even waste our time if module is not given
            if test -z (string replace -r '^.unload' '' $ret_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Please give a module to load/unload thanks"
                return
            end

            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Please wait"
            # Check if it even exists
            set -l module_fname_index 1
            for module in $loaded_modules
                if test "$module_name" = "$module"
                    # If so erase it
                    pr_debug "modules_load_unload" "Erasing $module_name from \$loaded_modules"
                    set -ge loaded_modules[$module_fname_index]
                    set module_exist true
                    break
                end
                set module_fname_index (math $module_fname_index + 1)
            end
            if test "$module_exist" = false
                pr_error "modules_load_unload" "Module $module_name does not exist."
                tg --editmsg "$ret_chat_id" "$sent_msg_id" "That module does not exist."
                return
            end

            # Find out which index the module's event is on
            set -l module_index 1
            for module in $loaded_modules
                if test "$module" = "$module_name"
                    break
                end
                set module_index (math $module_index + 1)
            end

            # Erase it
            set -l event_index 1
            for event in $modules_events
                if test "$event_index" -eq "$module_index"
                    pr_debug "modules_load_unload" "Erasing module $module_name's event ($modules_events[$event_index]) from \$event_index"
                    set -ge modules_events[$event_index]
                    break
                end
                set event_index (math $event_index + 1)
            end
        case '.load*'
            if not is_botowner
                err_not_botowner
                return
            end

            set -l module_name (string replace -r '^.load ' '' $ret_msg_text)

            # Do not even waste our time if module is not given
            if test -z (string replace -r '^.load' '' $ret_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Please give a module to load/unload thanks"
                return
            end

            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Please wait..."
            if not test -f $module_name
                pr_warn "modules_load_unload" "Cannot find $module_name!"
                pr_error "modules_load_unload" "Failed to load $module_name."
                tg --editmsg "$ret_chat_id" "$sent_msg_id" "That module does not exist."
                return
            end

            # Make sure it's not already loaded
            for module in $loaded_modules
                if test "$module" = "$module_name"
                    pr_warn "modules_load_unload" "Module $module is already loaded."
                    tg --editmsg "$ret_chat_id" "$sent_msg_id" "That module is already loaded."
                    return
                end
            end

            set -l old_modules_event $modules_events
            source $module_name
            if test "$old_modules_event" = "$modules_events"
                pr_warn "modules_load_unload" "Module $module_name does not append anything to \$modules_events"
                pr_error "modules_load_unload" "Failed to load $module_name"
                return
            end

            set -ga loaded_modules "$module_name"
    end
end
