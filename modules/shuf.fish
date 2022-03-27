#!/bin/bash

set -g __module_name "Shuffler"
set -g __module_description "Shuffle a replied message"
set -g __module_version 1
set -g __module_events shuffler
set -g __module_functions shuffle
set -g __module_help_message "\
$__module_description
`.shuf`, `.shuffle` \-\> Shuffle the replied message\. Avoid `.shuffle` to prevent conflicting with SamarBot\."

function shuffle --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.shuf' '.shuffle'
            test "$ret_replied_msg_id" != null
            or tg --replymsg "$ret_chat_id" "$ret_msg_id" "Reply to a message please" && return

            set -l message_split (string split ' ' $ret_replied_msg_text)
            set -l message_index (shuf -i 1-(count $message_split))
            set -l new_message
            for i in $message_index
                set -a new_message $message_split[$i]
            end

            tg --replymsg "$ret_chat_id" "$ret_msg_id" "$new_message"
    end
end
