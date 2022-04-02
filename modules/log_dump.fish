#!/bin/fish

set -g __module_name "Bot log access module (log_dump.fish)"
set -g __module_description "Not relevant to other than bot owner."
set -g __module_version 1
set -g __module_functions hakimi_afk bot_log
set -g __module_help_message "Irrelevant to other than bot owner\. Available commands:
`@hakimi0804` \-\> Tagging hakimi will trigger this module\.
`.dump \<LOGTYPE>` \-\> Dump log LOGTYPE\. Available types are warn, debug, error, info\."

function bot_log --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.dump*'
            if not is_botowner
                err_not_botowner
                return
            end

            test -z (string replace -r '^.dump' '' $ret_lowered_msg_text)
            and tg --replymsg $ret_chat_id $ret_msg_id "Please give a log type to dump." && return

            set -l logtype (string replace -r '^.dump ' '' $ret_lowered_msg_text)
            switch $logtype
                case info
                    bot_log::upload $PWD/logs/info.log
                case warn
                    bot_log::upload $PWD/logs/warn.log
                case error
                    bot_log::upload $PWD/logs/error.log
                case debug
                    bot_log::upload $PWD/logs/debug.log
                case '*'
                    tg --replymsg $ret_chat_id $ret_msg_id "Invalid log type specified."
            end
    end
end

function bot_log::upload
    set -l file_path $argv[1]
    test -z "$file_path"
    and pr_error log_dump "Function bot_log::upload error: File name not given (argv[1])" && return 1

    curl -s $API/sendDocument -F chat_id=$ret_chat_id -F reply_to_message_id=$ret_msg_id -F document=@$argv[1] | jq . >$curl_out
end
