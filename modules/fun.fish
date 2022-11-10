#!/bin/fish

set -g __module_name "Misc useless stuffs (fun.fish)"
set -g __module_description "Useless commands like gay and sexy. lol."
set -g __module_version 69
set -g __module_functions telegram
set -g __module_help_message "Bored? Try this module\!
`/gay` \-\> Determine your gayness\.
`/sexy`, `.sexy` \-\> Determine your sexiness\."

set -g cheat_user
set -a cheat_user 1554437068 # miko
set -a cheat_user 1655514932 # adib
set -a cheat_user 1084530895 # aqil

pr_debug fun "cheat users: $cheat_user"

function telegram --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '/gay*'
            tg --replymsg $ret_chat_id $ret_msg_id "Determining your gayness, please wait..."
            set -l level (shuf -i 0-165 -n1)
            while test $level -gt 100
                set level (shuf -i 0-165 -n1)
            end

            if contains -- $msgger $cheat_user
                tg --editmsg $ret_chat_id $sent_msg_id "You are 200% gay"
            else
                tg --editmsg $ret_chat_id $sent_msg_id "You are $level% gay"
            end
        case '/sexy*' '.sexy'
            tg --replymsg $ret_chat_id $ret_msg_id "Determining your sexiness, please wait..."
            set -l sexiness (shuf -i 0-165 -n1)
            while test $sexiness -gt 100
                set sexiness (shuf -i 0-165 -n1)
            end

            if contains -- $msgger $cheat_user
                tg --editmsg $ret_chat_id $sent_msg_id "You are -200% sexy"
            else
                tg --editmsg $ret_chat_id $sent_msg_id "You are $sexiness% sexy"
            end
    end
end
