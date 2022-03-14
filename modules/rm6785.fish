#!/bin/fish

set -ga modules_events "testing_group_rm6785_ch"
function realme_rm --on-event 'testing_group_rm6785_ch'
    switch $ret_lowered_msg_text
        case '.sticker*'
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Hold on..."
            tg --sendsticker "$fwd_to" "$rm6785_update_sticker"
            tg --editmsg "$ret_chat_id" "$sent_msg_id" "Sticker sent"
        case '.post*'
            if echo "$fwd_approved_chat_id" | grep -q "$ret_chat_id"
                if test "$ret_replied_msg_id" = null
                    tg --replymsg "$ret_chat_id" "$ret_msg_id" "Reply to a message please"
                    return
                else
                    tg --replymsg "$ret_chat_id" "$ret_msg_id" "Hold on..."
                    tg --cpmsg "$ret_chat_id" "$fwd_to" "$ret_replied_msg_id"
                    tg --editmsg "$ret_chat_id" "$sent_msg_id" "Posted"
                end
            else
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "You are not allowed to use this command outside testing group"
            end
    end
end
