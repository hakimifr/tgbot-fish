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
            test "$ret_replied_msg_id" != null
            or tg --replymsg "$ret_chat_id" "$ret_msg_id" "Reply to a message please" && return

            set -l message_split (string split ' ' $ret_replied_msg_text)
            set -l message_index (shuf -i 1-(count $message_split))
            set -l new_message
            for i in $message_index
                set -a new_message $message_split[$i]
            end

            tg --replymsg "$ret_chat_id" "$ret_msg_id" "$new_message"
        case '.insert'
            test "$ret_replied_msg_id" != null
            or tg --replymsg "$ret_chat_id" "$ret_msg_id" "Reply to a message please" && return

            # Pick random words in the words list
            set -l shuf_count (math (string split ' ' $ret_replied_msg_text | count) \* 2)
            set -l random_word_index (shuf -i 1-(count $shuf_words) -n$shuf_count)
            set -l random_words $shuf_words[$random_word_index]
            set -l pre_new_message_content (string split ' ' $ret_replied_msg_text) $random_words

            set -l new_message_content
            set -l randomised_index (shuf -i 1-(count $pre_new_message_content))
            for index in $randomised_index
                set -a new_message_content $pre_new_message_content[$index]
            end

            tg --replymsg "$ret_chat_id" "$ret_msg_id" "$new_message_content"
    end
end

# Module initialisation
pr_debug shuf "Loading words list"
set -g shuf_words (curl -sL https://github.com/dwyl/english-words/raw/master/words_alpha.zip | funzip | tr -d '\r')
# That file apparently contains carriage return, was figuring out for hours thinking fish is broken... -^^^^^^^^^^
# Windows should never exist in this world...

pr_debug shuf "Loaded words list"
