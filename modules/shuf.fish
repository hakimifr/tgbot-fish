#!/bin/fish

set -g __module_name Shuffler
set -g __module_description "Shuffle a replied message"
set -g __module_version 1
set -g __module_functions shuffle
set -g __module_help_message "\
$__module_description
`.shuf`, `.shuffle` \-\> Shuffle the replied message\. Avoid `.shuffle` to prevent conflicting with SamarBot\.
`.insert` \-\> Insert random words and shuffle replied message\."

function shuffle --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.shuf' '.shuffle'
            test $ret_replied_msg_id != null
            or tg --replymsg $ret_chat_id $ret_msg_id "Reply to a message please" && return

            set -l new_message (string split ' ' $ret_replied_msg_text | shuf)
            tg --replymsg $ret_chat_id $ret_msg_id "$new_message" # Must be quoted, all element in the list needs to become 3rd arg
        case '.insert'
            test $ret_replied_msg_id != null
            or tg --replymsg $ret_chat_id $ret_msg_id "Reply to a message please" && return

            # Pick random words in the words list
            set -l random_words (string split ' ' $shuf_words | shuf -n(string split ' ' $ret_replied_msg_text | count))
            set -l new_message_content (string split ' ' $random_words $ret_replied_msg_text | shuf)

            tg --replymsg $ret_chat_id $ret_msg_id "$new_message_content" # Must be quoted too, just like .shuf
    end
end

# Module initialisation
pr_debug shuf "Loading words list"
#set -g shuf_words (curl -sL https://github.com/dwyl/english-words/raw/master/words_alpha.zip | funzip | tr -d '\r')
# That file apparently contains carriage return, was figuring out for hours thinking fish is broken... -^^^^^^^^^^
# Windows should never exist in this world...

# That was not so fun, using my own word list
gh gist view https://gist.github.com/ccc81bc4bdb5a73ee8bd7ff02f710fd6 | source

pr_debug shuf "Loaded words list"
