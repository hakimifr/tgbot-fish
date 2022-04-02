#!/bin/fish
# If you ever use my bot, it is highly recommended that you
# do not remove/unload this module, as it serves as basic
# protection against spam.

set -g __module_name "Spam protection module (protector.fish)"
set -g __module_description "Not relevant to the average Joe."
set -g __module_version 1
set -g __module_functions protect
#set -g __module_help_message ""

function protect --on-event modules_trigger
    set -l update_ids (echo $global_fetch | jq .update_id)
    set -l update_ids_count (echo $update_ids | count)
    pr_debug protector "Update IDs count: $update_ids_count"

    test "$update_ids_count" -lt 10
    and return # No need to do anything

    for id in $update_ids
        curl -s $API/getUpdates -d offset=$id &>/dev/null &
    end
    wait
    tg --sendmsg -1001155763792 "Warning: The amout of pending updates exceeds tolerable treshold, thus has been dropped."
end
