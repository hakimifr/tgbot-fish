#!/bin/fish

set -g __module_name "RM6785 management module (rm6785.fish)"
set -g __module_description "Post ROMs and recovery without worrying about forward tag."
set -g __module_version 69
set -g __module_functions realme_rm
set -g __module_help_message "Irrelevant outside testing group\. Available commands:
`.sticker` \-\> Post update sticker to @RM6785\.
`.post <reply_to_a_message\>` \-\> Forward ROM/recovery post to @RM6785 without forward tag\.
`.auth` \-\> Authorize someone to use this module\.
`.unauth` \-\> Remove someone's authorization of using this module\.
`.reloadauthed` \-\> Reload authorized user, useful when you edit the gist\.

Deprecated commands:
`.postupdatesticker` \-\> Does the same as `.sticker`\.
`.fwdpost` \-\> Does the same as `.post`\."

set -g auth_gist_link "https://gist.github.com/3d681dec0fa904066e0030d5a528adcb"
set -g approval_count 0

function realme_rm --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.sticker' '.postupdatesticker'
            if contains -- $msgger $bot_owner_id $fwd_auth_user
                if contains -- $ret_chat_id $fwd_approved_chat_id
                    tg --replymsg $ret_chat_id $ret_msg_id "Hold on..."
                    tg --sendsticker $fwd_to $rm6785_update_sticker
                    tg --editmsg $ret_chat_id $sent_msg_id "Sticker sent"
                else
                    tg --replymsg $ret_chat_id $ret_msg_id "You are not allowed to use this command outside testing group"
                end
                return
            end
            tg --replymsg $ret_chat_id $ret_msg_id "You're not allowed to use this command"
        case '.post' '.fwdpost'
            if contains -- $msgger $bot_owner_id $fwd_auth_user
                if contains -- $ret_chat_id $fwd_approved_chat_id
                    if test "$ret_replied_msg_id" = null
                        tg --replymsg $ret_chat_id $ret_msg_id "Reply to a message please"
                    else
                        if test "$approval_count" -ge 2
                            tg --replymsg $ret_chat_id $ret_msg_id "Hold on..."
                            tg --cpmsg $ret_chat_id $fwd_to $ret_replied_msg_id
                            tg --editmsg $ret_chat_id $sent_msg_id Posted
                            set -g approval_count 0
                            set -g approved_users
                        else
                            tg --replymsg $ret_chat_id $ret_msg_id "Not enough approval ($approval_count/2)"
                        end
                    end
                else
                    tg --replymsg $ret_chat_id $ret_msg_id "You are not allowed to use this command outside testing group"
                end
                return
            end
            tg --replymsg $ret_chat_id $ret_msg_id "You're not allowed to do this bsdk"
        case '.approve' '.+1*'
            # Don't really need users to reply to a message but anyway
            if test "$ret_replied_msg_id" = null
                tg --replymsg $ret_chat_id $ret_msg_id "Reply to a message please"
                return
            end

            if not contains -- $msgger $approved_users
                if test "$approval_count" -lt 2
                    set -g approval_count (math $approval_count + 1)
                    tg --replymsg $ret_chat_id $ret_msg_id "Approval count: $approval_count/2"
                    set -a approved_users $msgger
                else
                    tg --replymsg $ret_chat_id $ret_msg_id "Message already have enough approval"
                end
            else
                tg --replymsg $ret_chat_id $ret_msg_id "You can only do this once"
            end
        case '.auth'
            set -l authorized false
            if contains -- $msgger $bot_owner_id $fwd_auth_user
                set authorized true
            end
            if test "$authorized" = true
                tg --replymsg $ret_chat_id $ret_msg_id "Authorizing that user"
                if test $ret_replied_msg_id = null
                    tg --editmsg $ret_chat_id $sent_msg_id "Reply to a user plox"
                else
                    set_authed_user
                    and tg --editmsg $ret_chat_id $sent_msg_id "That user is now authorized, enjoy"
                    or tg --editmsg $ret_chat_id $sent_msg_id "That user is already authorized"
                end
            else
                tg --replymsg $ret_chat_id $ret_msg_id "You're not allowed to do this bsdk"
            end
        case '.unauth'
            set -l authorized false
            if test "$msgger" = "$bot_owner_id"
                set authorized true
            end
            if test "$authorized" = true
                tg --replymsg $ret_chat_id $ret_msg_id "Unauthorizing that user that user"
                if test "$ret_replied_msg_id" = null
                    tg --editmsg $ret_chat_id $sent_msg_id "Reply to a user plox"
                else
                    remove_authed_user
                    and tg --editmsg $ret_chat_id $sent_msg_id "That user is now unauthorized, no more .post and .sticker for them."
                    or tg --editmsg $ret_chat_id $sent_msg_id "That user wasn't authorized"
                end
            else
                tg --replymsg $ret_chat_id $ret_msg_id "You're not allowed to do this bsdk"
            end
        case '.lsauthed'
            set -l auth_message
            set -l index 1
            for user in $fwd_auth_user
                if string match -qr -- '^@' $fwd_user_name[$index]
                    set -a auth_message "User [$user](t.me/$(string replace -r '^@' '' $fwd_user_name[$index] | string replace -a '_' '\\_'))"
                else
                    set -a auth_message "User $user \\- $(echo -n $fwd_user_name | sed 's/[][`~!@#\$%^&*()-_=+{}\|;:",<.>/?'"'"']/\\&/g')"
                end
                set index (math $index + 1)
            end
            tg --replymarkdownv2msg $ret_chat_id $ret_msg_id "
Authorized user to use `.post` and `.sticker`:
$(
for msg in $auth_message
    echo $msg
end
)
"
        case '.reloadauthed'
            if not is_botowner
                err_not_botowner
                return
            end
            tg --replymsg $ret_chat_id $ret_msg_id "Reading gist..."
            read_authed_user
            tg --editmsg $ret_chat_id $sent_msg_id "Authorized user reloaded"
    end
end

function read_authed_user
    gh gist view $auth_gist_link | source
end

function set_authed_user
    if string match -q -- $ret_replied_msgger_id $fwd_auth_user
        return 1
    end
    set -l new_gist_content "set -g fwd_auth_user $fwd_auth_user $ret_replied_msgger_id"
    test "$ret_username" = null
    and set -a new_gist_content "set -g fwd_user_name $fwd_user_name \"$ret_replied_first_name\""
    or set -a new_gist_content "set -g fwd_user_name $fwd_user_name @$ret_replied_username"
    for item in $new_gist_content
        echo $item
    end | gh gist edit $auth_gist_link -
    for item in $new_gist_content
        echo $item
    end | source
    return 0
end

function remove_authed_user
    if not string match -q -- $ret_replied_msgger_id $fwd_auth_user
        return 1
    end
    # Find out index
    set -l index 1
    for user in $fwd_auth_user
        if string match -q -- $user $ret_replied_msgger_id
            break
        end
        set index (math $index + 1)
    end
    set -ge fwd_auth_user[$index]
    set -ge fwd_user_name[$index]
    set -l new_gist_content "set -g fwd_auth_user $fwd_auth_user" "set -g fwd_user_name $fwd_user_name"
    for item in $new_gist_content
        echo $item
    end | gh gist edit $auth_gist_link -
    for item in $new_gist_content
        echo $item
    end | source
    return 0
end

function gh_init
    read_authed_user
end

gh_init
