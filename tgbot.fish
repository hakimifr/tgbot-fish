#!/bin/fish

set width $COLUMNS
set text "Sourcing core scripts"
set_color -b brmagenta; set_color black; echo -n "$text"; set_color normal
set count (echo "$text" | string split '' | count)
for i in (seq (math $width - $count))
    set_color -b brmagenta; echo -n ' '
end
set_color normal; echo
set -e width count i text

source extra.fish
source util.fish
source modules_loader.fish

update_init
while true
    update
    set -ge ret_lowered_msg_text
    set -g ret_lowered_msg_text (string lower "$ret_msg_text")
    test -n "$ret_lowered_msg_text" && echo "Text received: $ret_lowered_msg_text"

    # Run modules
    run_modules

    switch "$ret_lowered_msg_text"
        case '/help*' '.help*'
            tg --replymarkdownv2msg "$ret_chat_id" "$ret_msg_id" "$help_message" # $help_message located on extra.fish
        case '/test*' '.test*'
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "bot is running"
        case '.calc*'
            set -l trimmed (string replace -r '^.calc' '' $ret_lowered_msg_text)
            set -l calced (echo $trimmed | bc -l 2>&1)
            if not echo "$calced" | grep -qi 'syntax error'
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "$calced"
            else
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Error occured"
            end
        case '.magisk*'
            tg --sendmsg "$RET_CHAT_ID" "Fetching latest Magisk stable"
            set -l latest (
                curl -s https://api.github.com/repos/topjohnwu/Magisk/releases/latest |
                    grep "Magisk-v**.*.apk" |
                    cut -d : -f 2,3 |
                    tr -d \" |
                    cut -d, -f2 |
                    tr -d '\n' |
                    tr -d ' '
            )
            set -l canary "https://raw.githubusercontent.com/topjohnwu/magisk-files/canary/app-debug.apk"
            tg --editmarkdownv2msg "$RET_CHAT_ID" "$SENT_MSG_ID" "[Latest stable]($LATEST_STABLE)"
        case '.neofetch'
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "This may take a while as there's quite a few packages in this laptop..."
            set -l neofetch_output (neofetch --stdout)
            tg --editmsg "$ret_chat_id" "$sent_msg_id" "$neofetch_output"
        case '.save'
            if not is_botowner
                err_not_botowner
                set -ge ret_lowered_msg_text ret_msg_text
                continue
            else if test "$ret_replied_msg_id" = null
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Reply to a message to save thx"
                set -ge ret_lowered_msg_text ret_msg_text
                continue
            end
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Please wait..."
            tg --forwardmsg "$ret_chat_id" "$saving_group_id" "$ret_replied_msg_id"
            tg --editmsg "$ret_chat_id" "$sent_msg_id" "Message forwarded"
        case '*@hakimi0804*'
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Saving this message link so Hakimi can read it later..."
            set -l reply_msg_id $sent_msg_id
            set -l group_id (string replace -r -- '^-100' '' $ret_chat_id)
            tg --sendmsg "$tagger_group_id" "New tag: https://t.me/c/$group_id/$ret_msg_id"
            tg --delmsg "$ret_chat_id" "$reply_msg_id"
        case '/gay*'
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Determining your gayness, please wait..."
            set -l level (shuf -i 0-165 -n1)
            while test "$level" -gt 100
                set level (shuf -i 0-165 -n1)
            end
            tg --editmsg "$ret_chat_id" "$sent_msg_id" "You are $level% gay"
        case '/sexy*' '.sexy'
            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Determining your sexiness, please wait..."
            set -l sexiness (shuf -i 0-165 -n1)
            while test "$sexiness" -gt 100
                set sexiness (shuf -i 0-165 -n1)
            end
            tg --editmsg "$ret_chat_id" "$sent_msg_id" "You are $sexiness% level sexy"
    end
    set -ge ret_lowered_msg_text
    set -ge ret_msg_text
end
