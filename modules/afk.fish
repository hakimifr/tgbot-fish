#!/bin/fish

set -g __module_name "AFK module (hakimi_afk.fish)"
set -g __module_description "Hakimi loads this module when he is AFK."
set -g __module_version 69
set -g __module_functions hakimi_afk "afk::editmsg"
set -g __module_help_message "Irrelevant to other than bot owner\. Available commands:
`@hakimi0804` \-\> Tagging hakimi will trigger this module\.
`.editafkreason` \-\> Edit AFK reason\."

function hakimi_afk -d "Hakimi's AFK module" --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '*@hakimi0804*'
            afk::replymsg "AFK MODULE: Hakimi is afk \\(Most probably sleeping\\)\\. View details of this module with `\\.modinfo hakimi_afk.fish`\\. List all loaded module with `\\.lsmod`\\.
AFK reason: https://gist\\.github\\.com/9e6cc003c83533a2815898f9b27196ce
_This message will auto\\-delete in 3 sec_"
            sleep 3
            tg --delmsg "$ret_chat_id" "$__afk_del_id"
        case '.editafkreason*'
            if not is_botowner
                err_not_botowner
                return
            end
            if test -z (string replace -r '^.editafkreason' '' $ret_lowered_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "Empty text. Please specify a few reasons."
            else
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "One moment"
                echo "$(string replace -r '^.editafkreason ' '' $ret_msg_text)" | gh gist edit https://gist.github.com/9e6cc003c83533a2815898f9b27196ce -
                afk::editmsg "Reason edited\\. View it: https://gist\\.github\\.com/9e6cc003c83533a2815898f9b27196ce"
            end
    end
end

function afk::editmsg
    curl -s "$API/editMessageText" \
        -d "chat_id=$ret_chat_id" \
        -d "message_id=$sent_msg_id" \
        -d "text=$argv[1]" \
        -d "parse_mode=MarkdownV2" \
        -d "disable_web_page_preview=true"
end

function afk::replymsg
    set -g __afk_del_id (curl -s "$API/sendMessage" \
        -d "chat_id=$ret_chat_id" \
        -d "message_id=$sent_msg_id" \
        -d "reply_to_message_id=$ret_msg_id" \
        -d "text=$argv[1]" \
        -d "parse_mode=MarkdownV2" \
        -d "disable_web_page_preview=true" | jq .result.message_id)
end
