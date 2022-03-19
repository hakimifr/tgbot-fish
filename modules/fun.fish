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
        case '/gay*'
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Determining your gayness, please wait..."
            set -l level (shuf -i 0-165 -n1)
            while test "$level" -gt 100
                set level (shuf -i 0-165 -n1)
            end
            tg --editmsg "$ret_chat_id" "$sent_msg_id" "You are $level% gay"
        case '/sexy*' '.sexy'
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Determining your sexiness, please wait..."
            set -l sexiness (shuf -i 0-165 -n1)
            while test "$sexiness" -gt 100
                set sexiness (shuf -i 0-165 -n1)
            end
            tg --editmsg "$ret_chat_id" "$sent_msg_id" "You are $sexiness% sexy"
    end
end
