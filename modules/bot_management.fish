#!/bin/fish

set -g __module_name "Bot management module (bot_management.fish)"
set -g __module_description "Stuffs like .restart and .reload."
set -g __module_version 69
set -g __module_functions bot_management bot_management::update
set -g __module_help_message "Irrelevant to other than bot owner\. Available commands:
`.restart` \-\> Restart the bot\. Quite buggy\.
`.reload` \-\> Reload all modules\."

if test "$bot_restarted" = true
    set -ge ret_lowered_msg_text
    set -ge ret_msg_text
    tg --editmsg $tmp_ret_chat_id $tmp_sent_msg_id "Bot restarted"
    set -ge tmp_ret_chat_id
    set -ge tmp_sent_msg_id
end

function bot_management --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.restart'
            if not is_botowner
                err_not_botowner
                return
            end
            if test "$bot_restarted" = true
                set -ge bot_restarted
                set -ge ret_lowered_msg_text
                set -g update_id (math $update_id + 1)
            else
                tg --replymsg $ret_chat_id $ret_msg_id "Restarting bot"
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
            for module in (find metadata -type f -iname '*.fish')
                __module_unload $module
            end
            tg --replymsg $ret_chat_id $ret_msg_id "Reloading all modules"
            set -ge modules_events
            set -ge modules_functions
            load_modules
            tg --editmsg $ret_chat_id $sent_msg_id "Modules reloaded"
        case '.update'
            if not is_botowner
                err_not_botowner
                return
            end
            bot_management::update
    end
end

function bot_management::update
    tg --replymsg $ret_chat_id $ret_msg_id "Updating bot"
    pr_info bot_management::update "Updating bot"
    pr_debug bot_management::update "Adding safe dir to git"

    pr_debug bot_management::update "Running git pull"
    git config --global --add safe.directory /app ||
        begin
            pr_info bot_management::update "Normal git pull failed, trying from scratch.."
            git update-ref -d HEAD
            git pull
        end || set -l bot_update_error true

    if test "$bot_update_error" = true
        pr_error bot_management::update "Bot update failed."
        tg --editmsg $ret_chat_id $sent_msg_id "Bot updated failed! please check logs"
        return
    end

    pr_info bot_management::update "Bot updated successfully, restart recommended."

    tg --editmsg $ret_chat_id $sent_msg_id "Bot updated successfully, restart recommended."
end

