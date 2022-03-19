#!/bin/fish

set -g __module_name "Misc useless stuffs (fun.fish)"
set -g __module_description "Useless commands like gay and sexy. lol."
set -g __module_version 69
set -g __module_events "telegram-me"
set -g __module_functions "telegram"

function telegram --on-event 'telegram-me'
    switch $ret_lowered_msg_text
        case '*t.me*'
            set -l new_message (string replace 't.me' 'telegram.dog' $ret_msg_text)
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Automatic telegram.dog conversion
$new_message"
    end
end
