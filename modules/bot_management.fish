#!/bin/fish

set -g __module_name "Bot management module (bot_management.fish)"
set -g __module_description "Stuffs like .restart and .reload."
set -g __module_version 69
set -g __module_events management
set -g __module_functions bot_management
set -g __module_help_message "Irrelevant to other than bot owner\. Available commands:
`.restart` \-\> Restart the bot\. Quite buggy\.
`.reload` \-\> Reload all modules\."

if test "$bot_restarted" = true
    set -ge ret_lowered_msg_text
    set -ge ret_msg_text
    set -g update_id (math $update_id + 1)
    tg --editmsg "$tmp_ret_chat_id" "$tmp_sent_msg_id" "Bot restarted"
    set -ge tmp_ret_chat_id
    set -ge tmp_sent_msg_id
end

function bot_management --on-event management
    switch $ret_lowered_msg_text
        case '.restart'
            if not is_botowner
                err_not_botowner
                return
            end
            if test "$bot_restarted" = true
                set -ge bot_restarted
            else
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Restarting bot"
                set -gx bot_restarted true
                set -gx tmp_ret_chat_id $ret_chat_id
                set -gx tmp_sent_msg_id $sent_msg_id
                set -gx update_id
                exec ./tgbot.fish
            end
        case '.reload'
            if not is_botowner
                err_not_botowner
                return
            end
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Reloading all modules"
            set -ge modules_events
            set -ge modules_functions
            load_modules
            tg --editmsg "$ret_chat_id" "$sent_msg_id" "Modules reloaded"
    end
end
