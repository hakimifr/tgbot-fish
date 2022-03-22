#!/bin/fish

set -g __module_name "RM6785 management module (rm6785.fish)"
set -g __module_description "Post ROMs and recovery without worrying about forward tag."
set -g __module_version 69
set -g __module_events testing_group_rm6785_ch
set -g __module_functions realme_rm
set -g __module_help_message "Irrelevant outside testing group\. Available commands:
`.sticker` \-\> Post update sticker to @RM6785\.
`.post <reply_to_a_message\>` \-\> Forward ROM/recovery post to @RM6785 without forward tag\.
`.auth` \-\> Authorize someone to use this module\.
`.unauth` \-\> Remove someone's authorization of using this module\.

Deprecated commands:
`.postupdatesticker` \-\> Does the same as `.sticker`\.
`.fwdpost` \-\> Does the same as `.post`\."

set -g auth_gist_link "https://gist.github.com/3d681dec0fa904066e0030d5a528adcb"

function realme_rm --on-event testing_group_rm6785_ch
    switch $ret_lowered_msg_text
        case '.sticker' '.postupdatesticker'
            for user in $bot_owner_id $fwd_auth_user
                if test "$msgger" = "$user"
                    if string match -qe -- "$ret_chat_id" "$fwd_approved_chat_id"
                        tg --replymsg "$ret_chat_id" "$ret_msg_id" "Hold on..."
                        tg --sendsticker "$fwd_to" "$rm6785_update_sticker"
                        tg --editmsg "$ret_chat_id" "$sent_msg_id" "Sticker sent"
                    else
                        tg --replymsg "$ret_chat_id" "$ret_msg_id" "You are not allowed to use this command outside testing group"
                    end
                    return
                end
            end
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "You're not allowed to use this command"
        case '.post' '.fwdpost'
            for user in $bot_owner_id $fwd_auth_user
                if test "$msgger" = "$user"
                    if string match -qe -- "$ret_chat_id" "$fwd_approved_chat_id"
                        if test "$ret_replied_msg_id" = null
                            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Reply to a message please"
                        else
                            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Hold on..."
                            tg --cpmsg "$ret_chat_id" "$fwd_to" "$ret_replied_msg_id"
                            tg --editmsg "$ret_chat_id" "$sent_msg_id" Posted
                        end
                    else
                    end
                    return
                end
            end
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "You're not allowed to do this bsdk"
        case '.auth'
            set -l authorized false
            for user in $bot_owner_id $fwd_auth_user
                if test "$msgger" = "$user"
                    set authorized true
                    break
                end
            end
            if test $authorized = true
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Authorizing that user"
                if test "$ret_replied_msg_id" = null
                    tg --editmsg "$ret_chat_id" "$sent_msg_id" "Reply to a user plox"
                else
                    set_authed_user "$ret_replied_msgger_id"
                    tg --editmsg "$ret_chat_id" "$sent_msg_id" "That user is now authorized, enjoy"
                end
            else
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "You're not allowed to do this bsdk"
            end
        case '.unauth'
            set -l authorized false
            if test "$msgger" = "$bot_owner_id"
                set authorized true
            end
            if test $authorized = true
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Unauthorizing that user that user"
                if test "$ret_replied_msg_id" = null
                    tg --editmsg "$ret_chat_id" "$sent_msg_id" "Reply to a user plox"
                else
                    remove_authed_user "$ret_replied_msgger_id"
                    tg --editmsg "$ret_chat_id" "$sent_msg_id" "That user is now unauthorized, no more .post and .sticker for them."
                end
            else
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "You're not allowed to do this bsdk"
            end
        case '.lsauthed'
            set -l authed_user (cat modules/assets/rm6785_auth_user)
            set -l mention_user
            for user in $authed_user
                set -a mention_user "[User $user](tg://user?id=$user)"
            end
            tg --replymarkdownv2msg "$ret_chat_id" "$ret_msg_id" "\
Authorized user to use `\\.post` and `\\.sticker`:
$(for user in $mention_user; string replace -a '-' '\\-' $user; end)
"
    end
end

function read_authed_user
    gh gist view $auth_gist_link | source
end

function set_authed_user
    if not set -q argv[1]
        return 1
    end
    set -l new_gist_content "set -g fwd_auth_user $fwd_auth_user $argv[1]"
    echo -n $new_gist_content | gh gist edit $auth_gist_link -
    echo $new_gist_content | source
end

function remove_authed_user
    if not set -q argv[1]
        return 1
    end
    set -l fwd_auth_user (gh gist view $auth_gist_link | string replace -- "$argv[1]" '' | source)
    set -l new_gist_content "set -g fwd_auth_user $fwd_auth_user"
    echo $new_gist_content | source # Because why not
end

function gh_auth
    if not set -q GIST_TOKEN
        return
    end
    echo $GIST_TOKEN >modules/assets/gh_token
    gh auth login --with-token <modules/assets/gh_token
    rm -f modules/assets/gh_token
    set -ge GIST_TOKEN
end

function gh_init
    gh_auth
    read_authed_user
end

gh_init
