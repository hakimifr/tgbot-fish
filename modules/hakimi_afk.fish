#!/bin/fish

set -g __module_name "AFK module (hakimi_afk.fish)"
set -g __module_description "Hakimi loads this module when he is AFK."
set -g __module_version 69
set -g __module_events "afk"
set -g __module_functions "hakimi_afk"

function hakimi_afk -d "Hakimi's AFK module" --on-event 'afk'
    switch $ret_lowered_msg_text
        case '*@hakimi0804*'
            tg --replymarkdownv2msg "$ret_chat_id" "$ret_msg_id" "AFK MODULE: Hakimi is afk \\(Most probably sleeping\\)
_This message will auto-delete in 2 sec_"
            sleep 2
            tg --delmsg "$ret_chat_id" "$ret_msg_id"
    end
end
