#!/bin/fish

set -g __module_name "RM6785 management module (rm6785.fish)"
set -g __module_description "Post ROMs and recovery without worrying about forward tag."
set -g __module_version 69
set -g __module_functions realme_rm
set -g __module_help_message "Irrelevant outside testing group\. Available commands:
`.sticker` \-\> Post update sticker to @RM6785\.
`.post` <reply\_to\_a\_message\> \-\> Forward ROM/recovery post to @RM6785 without forward tag\.
`.spost` <reply\_to\_a\_message\> \-\> Same as post, but send a sticker before forwarding post\.
`.fpost` \-\> \(bot owner only\) Force post without enough approval\.
`.lint` \-\> Lint a post
`.auth` \-\> Authorize someone to use this module\.
`.unauth` \-\> Remove someone's authorization of using this module\.
`.lsauthed` \-\> List authorized users\.
`.reloadauthed` \-\> Reload authorized user, useful when you edit the gist\.
`.approve`, `.+1` \-\> Approve a message to be posted\.
`.unapprove`, `.-1` \-\> Unapprove a message to be posted\.
`.approval` \-\> View approval count\.
`.resetapproval` \-\> \(bot owner only\) Reset approval counter\.

Deprecated commands:
`.postupdatesticker` \-\> Does the same as `.sticker`\.
`.fwdpost` \-\> Does the same as `.post`\."

set -g auth_gist_link "https://gist.github.com/3d681dec0fa904066e0030d5a528adcb"
set -g approval_count 0
set -g approved_users
set -g unapproved_users
set -g rm6785_id -1001754321934
set -g samar_id 1138003186

# tg --cpmsg doesn't set $sent_msg_id, im pretty sure i've
# a module which relies on it not doing that, so unfortunately
# i'll have to define a function that does the same but instead
# storing the $sent_msg_id
function copyMessage
    set -l result (curl -s $API/copyMessage -F from_chat_id=$argv[1] -F chat_id=$argv[2] -F message_id=$argv[3])
    set -g __rm6785_sent_msg_id (echo $result | jq '.result.message_id')
end

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
        case '.post' '.spost' '.fwdpost'
            if contains -- $msgger $bot_owner_id $fwd_auth_user
                if contains -- $ret_chat_id $fwd_approved_chat_id
                    if test "$ret_replied_msg_id" = null
                        tg --replymsg $ret_chat_id $ret_msg_id "Reply to a message please"
                    else
                        if test "$approval_count" -ge 2
                            tg --replymsg $ret_chat_id $ret_msg_id "Hold on..."

                            if test "$ret_lowered_msg_text" = ".spost"
                                tg --sendsticker $fwd_to $rm6785_update_sticker
                            end

                            tg --cpmsg $ret_chat_id $fwd_to $ret_replied_msg_id
                            copyMessage $ret_chat_id $rm6785_id $ret_replied_msg_id
                            tg --pinmsg $rm6785_id $__rm6785_sent_msg_id
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
        case '.fpost'
            if test "$msgger" = "$bot_owner_id"
            or test "$msgger" = "$samar_id"
                if test "$ret_replied_msg_id" = null
                    tg --replymsg $ret_chat_id $ret_msg_id "Reply to a message please"
                else
                    tg --replymsg $ret_chat_id $ret_msg_id "Hold on... Force posting with $approval_count/2 approval"
                    tg --cpmsg $ret_chat_id $fwd_to $ret_replied_msg_id
                    copyMessage $ret_chat_id $rm6785_id $ret_replied_msg_id
                    tg --pinmsg $rm6785_id $__rm6785_sent_msg_id
                    tg --editmsg $ret_chat_id $sent_msg_id Posted
                end
            else
                tg --replymsg $ret_chat_id $ret_msg_id "Only usable by bot owner"
            end
        case '.approve' '.+1*'
            # Don't really need users to reply to a message but anyway
            ensure_reply
            or return

            if contains -- $msgger $bot_owner_id $fwd_auth_user
                if not contains -- $msgger $approved_users
                    if test "$approval_count" -lt 2
                        set -g approval_count (math $approval_count + 1)
                        tg --replymsg $ret_chat_id $ret_msg_id "Approval count: $approval_count/2"
                        set -a approved_users $msgger

                        # Remove the user from $unapproved_users if they're there
                        if contains -- $msgger $unapproved_users
                            set -l index (contains -i -- $msgger $unapproved_users)
                            set -e unapproved_users[$index]
                        end
                    else
                        tg --replymsg $ret_chat_id $ret_msg_id "Message already have enough approval"
                    end
                else
                    tg --replymsg $ret_chat_id $ret_msg_id "You can only do this once"
                end
            else
                tg --replymsg $ret_chat_id $ret_msg_id "You're not allowed to do this bsdk"
            end
        case '.unapprove' '.-1'
            ensure_reply
            or return

            if contains -- $msgger $bot_owner_id $fwd_auth_user
                if not contains -- $msgger $unapproved_users
                    set -g approval_count (math $approval_count - 1)
                    tg --replymsg $ret_chat_id $ret_msg_id "approval count: $approval_count/2"
                    set -a unapproved_users $msgger

                    # Remove the user from $approved_users if they're there
                    if contains -- $msgger $approved_users
                        set -l index (contains -i -- $msgger $approved_users)
                        set -e approved_users[$index]
                    end
                else
                    tg --replymsg $ret_chat_id $ret_msg_id "You can only do this once"
                end
            else
                tg --replymsg $ret_chat_id $ret_msg_id "You're not allowed to do this bsdk"
            end
        case '.approval'
            tg --replymsg $ret_chat_id $ret_msg_id "Approval count: $approval_count/2"
        case '.resetapproval'
            if not is_botowner
                err_not_botowner
                return
            end

            set -g approval_count 0
            set -g approved_users
            set -g unapproved_users

            tg --replymsg $ret_chat_id $ret_msg_id "Counter resetted. Approval  count: $approval_count/2"
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
                    set -a auth_message "User [$(echo $fwd_user_name[$index] | string replace -r '^@' '' | string replace -a '_' '\\_')](t.me/$(string replace -r '^@' '' $fwd_user_name[$index] | string replace -a '_' '\\_'))"
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

        case '.lint'
            if test "$ret_replied_msg_id" = null
                tg --replymsg $ret_chat_id $ret_msg_id "Reply to a message"
                return
            end

            tg --replymsg $ret_chat_id $ret_msg_id "Linting"

            ### LINT ###
            set -l problems
            # 1. Author, Android version, Build date
            string match -q -- "• Author:" $ret_replied_msg_text
            or set -a problems "Missing author" $ret_replied_msg_text
            string match -q -- "• Android version:" $ret_replied_msg_text
            or set -a problems "Missing Android version" $ret_replied_msg_text
            string match -q -- "• Build date:" $ret_replied_msg_text
            or set -a problems "Missing build date" $ret_replied_msg_text

            # Wrong build date format
            if string match -q -- "• Build date:" $ret_replied_msg_text
            and not string match -qr -- "• Build date: ..-..-...."
                set -a problems "Wrong build date format"
            end

            # Changelog, Bugs, Notes, Downloads
            string match -q -- "Changelog" $ret_replied_msg_text
            or set -a problems "Missing Changelog"
            string match -q -- "Bugs" $ret_replied_msg_text
            or set -a problems "Missing bugs"
            string match -q -- "Notes" $ret_replied_msg_text
            or set -a problems "Missing Notes"
            string match -q -- "Downloads"
            or set -a problems "Missing Downloads"

            # Bold check
            if string match -q -- "Changelog" $ret_replied_msg_text
            and not string match -q -- "*Changelog*"
                set -a problems "Changelog is not bold"
            end
            if string match -q -- "Bugs" $ret_replied_msg_text
            and not string match -q -- "*Bugs*"
                set -a problems "Bugs is not bold"
            end
            if string match -q -- "Notes" $ret_replied_msg_text
            and not string match -q --  "*Notes*" $ret_replied_msg_text
                set -a problems "Notes is not bold"
            end
            if string match -q -- "Downloads" $ret_replied_msg_text
            and not string match -q -- "*Downloads*" $ret_replied_msg_text
                set -a problems "Downloads is not bold"
            end

            # Miscs
            string match -q -- "Screenshots" $ret_replied_msg_text
            or set -a problems "Missing Screenshots"
            string match -q -- "Sources" $ret_replied_msg_text
            or set -a problems "Missing Sources"
            string match -q -- "Support group" $ret_replied_msg_text
            or set -a problems "Missing Support group"

            if test (count $problems) -eq 0
                tg --editmsg $ret_chat_id $sent_msg_id "No issues found"
            else
                tg --editmsg $ret_chat_id $sent_msg_id "Issues found:
$(printf -- '- %s\n' $problems)"  # Fish's builtin printf doesn't like - without -- so yeah
            end
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
