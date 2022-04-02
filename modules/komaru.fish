#!/bin/fish

set -g __module_name "Komaru GIFs"
set -g __module_description "Send you random Komaru GIF"
set -g __module_version 1
set -g __module_functions komaru_handler komaru_handler_channel_auto
set -g __module_help_message "\
$__module_description
`.komaru` \-\> Return random Komaru GIF\.
`.add` \-\> Add a Komaru GIF\. Reply to a message\. Automatic duplicate checks\.
`.kdeterdup` \-\> Determine whether a GIF already exists in database aka duplicate\.
`.forceupdatedb` \-\> Force update komaru GIF list by setting last check time as expired\."

set -g komaru_gist_link "https://gist.github.com/Hakimi0804/ce08621726a75310e8be7f34e9cdb1ee"

function komaru_handler --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.komaru'
            komaru_handler::ref_gist
            komaru_handler::pick_random_komaru
            reply_file $ret_chat_id $ret_msg_id $random_komaru
        case '.add'
            test $ret_replied_msg_id != null
            or tg --replymsg $ret_chat_id $ret_msg_id "Reply to a message please" && return

            tg --replymsg $ret_chat_id $ret_msg_id "One moment, determining duplicate"
            komaru_handler::deter_dup
            and komaru_handler::add_gif $ret_replied_file_id
            or tg --editmsg $ret_chat_id $sent_msg_id "Duplicate check failed, This GIF is a duplicate."
        case '.kdeterdup'
            test $ret_replied_msg_id != null
            or tg --replymsg $ret_chat_id $ret_msg_id "Reply to a message please" && return

            tg --replymsg $ret_chat_id $ret_msg_id "Determining duplicate..."
            komaru_handler::deter_dup
            and tg --editmsg $ret_chat_id $sent_msg_id "This GIF is not a duplicate."
            or tg --editmsg $ret_chat_id $sent_msg_id "This GIF is a duplicate."
        case '.forceupdatedb'
            if not is_botowner
                err_not_botowner
                return
            end
            set -l tmp_chat_id $ret_chat_id
            set -g ret_chat_id 0 # Prevent refresh function from replying, we're gonna use our own
            tg --replymsg $tmp_chat_id $ret_msg_id "Refreshing komaru database"
            set -l tmp_msg_id $sent_msg_id

            set -l new_time (math (cat modules/assets/komaru_metadata) - 2000) # 1800 is enough but WHY NOT righht
            echo $new_time >modules/assets/komaru_metadata
            komaru_handler::ref_gist
            tg --editmsg $tmp_chat_id $tmp_msg_id Refreshed

            # Restore the variable, prevent breaking other modules
            set -g ret_chat_id $tmp_chat_id
        case '.count'
            tg --replymarkdownv2msg $ret_chat_id $ret_msg_id "Komaru GIFs count: $(count $komaru_unique_id)
If this is not the same with the channel, the GIFs database is probably outdated\. Add missing GIFs with `.add`\."
    end
end

function komaru_handler_channel_auto --on-event modules_trigger
    # Setting vars, channel works differently
    set -l channel_id (echo $global_fetch | jq .channel_post.chat.id)
    set -l message_id (echo $global_fetch | jq .channel_post.message_id)
    set -l file_unique_id (echo $global_fetch | jq -r .channel_post.document.file_unique_id)
    set -l file_id (echo $global_fetch | jq -r .channel_post.document.file_id)

    # Just like util.fish
    set -l channel_id $channel_id[1]
    set -l message_id $message_id[1]
    set -l file_unique_id $file_unique_id[1]
    set -l file_id $file_id[1]

    pr_debug komaru "Auto ch dedup: channel id - $channel_id"
    pr_debug komaru "Auto ch dedup: file unique id - $file_unique_id"
    pr_debug komaru "Auto ch dedup: message id - $message_id"

    test "$channel_id" != -1001750281318
    and return

    test "$file_unique_id" = null
    and return

    # Temporarily set replied var to non-replied one, because komaru_handler::deter_dup uses replied one
    # but we want to check non-replied one.
    tg --replymsg $channel_id $message_id "Determining for duplicate"
    set -l old_ret_replied_file_unique_id $ret_replied_file_unique_id
    set -l old_ret_replied_file_id $ret_replied_file_id
    set -g ret_replied_file_unique_id $file_unique_id
    set -g ret_replied_file_id $file_id

    komaru_handler::deter_dup
    if test $status -eq 0
        tg --editmsg $channel_id $sent_msg_id "Duplicate check succeeded. Adding GIF to database. Message will auto-delete in 3 sec"
        fish -c "
        source util.fish;
        source .token.fish;
        sleep 3;
        tg --delmsg $channel_id $sent_msg_id;
        " &
    else
        tg --editmsg $channel_id $sent_msg_id "Duplicate check failed, deleting GIF in 3 sec"
        fish -c "
        source util.fish
        source .token.fish;
        sleep 3;
        tg --delmsg $channel_id $message_id
        tg --delmsg $channel_id $sent_msg_id
        " &
    end

    # Reset back the var
    set -g ret_replied_file_unique_id $old_ret_replied_file_unique_id
    set -g ret_replied_file_id $old_ret_replied_file_id
end

function komaru_handler::deter_dup
    for uid in $komaru_unique_id
        if test "$uid" = "$ret_replied_file_unique_id"
            return 1
        end
    end
    return 0
end

function komaru_handler::add_gif
    set -ga komaru_id $ret_replied_file_id
    set -ga komaru_unique_id $ret_replied_file_unique_id
    echo "set -g komaru_id $komaru_id" >modules/assets/komaru-id.fish
    echo "set -g komaru_unique_id $komaru_unique_id" >>modules/assets/komaru-id.fish
    gh gist edit $komaru_gist_link - <modules/assets/komaru-id.fish
    tg --editmsg $ret_chat_id $sent_msg_id "Duplicate check succeeded, GIF added"
end

function komaru_handler::ref_gist
    # Determine if we need to refresh gist
    set -g last_refresh_date (cat modules/assets/komaru_metadata)
    if test (math (date +%s) - $last_refresh_date) -gt 1800 # 30mins
        tg --replymsg $ret_chat_id $ret_msg_id "Uh oh! GIF list expired. Refreshing, this should not take too long..."
        gh gist view $komaru_gist_link | source
        date +%s >modules/assets/komaru_metadata
        tg --delmsg $ret_chat_id $sent_msg_id
    end
end

# komaru_id
# komaru_unique_id
function komaru_handler::pick_random_komaru
    set -l komaru_index (shuf -i 1-(count $komaru_id) -n1)
    set -g random_komaru $komaru_id[$komaru_index]
end

function reply_file
    set -l chat_id $argv[1]
    set -l message_id $argv[2]
    set -l file_id $argv[3]
    pr_debug komaru "chat ID: $chat_id"
    pr_debug komaru "msg ID: $message_id"
    pr_debug komaru "file ID: $file_id"
    curl -s $API/sendDocument -d chat_id=$chat_id -d reply_to_message_id=$message_id -d document=$file_id | jq .
end

function komaru_init
    date +%s >modules/assets/komaru_metadata
    set -g last_refresh_date (cat modules/assets/komaru_metadata)
    gh gist view $komaru_gist_link | source
end

komaru_init
