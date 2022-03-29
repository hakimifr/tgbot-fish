#!/bin/fish

set -g __module_name shell
set -g __module_description "Run shell commands"
set -g __module_version 1
set -g __module_functions shell_exec
set -g __module_help_message "\
$__module_description
`.exec`, `.shell` \-\> Execute a shell commands
"

function shell_exec --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.exec*' '.shell*'
            if not is_botowner
                err_not_botowner
                return
            end

            # Make sure we have any commands
            if test -z (string replace -r '^.exec' '' $ret_lowered_msg_text); or test -z (string replace -r '^.shell' '' $ret_lowered_msg_text)
                tg --replymsg "$ret_chat_id" "$ret_msg_id" "No command given."
                return
            end

            if string match -r '^.exec' $ret_lowered_msg_text
                set -f bot_command '.exec'
            else if string match -r '^.shell' $ret_lowered_msg_text
                set -f bot_command '.shell'
            end

            tg --replymsg "$ret_chat_id" "$ret_msg_id" "Running command."

            # Helper script accepts 3 args, of which:
            # 1 - chat id
            # 2 - message id
            # 3 - the commands
            set -l args "$ret_chat_id" "$ret_msg_id" "$(string replace -r "^$bot_command " '' $ret_msg_text)" # Quote to not split, not even newline
            fish modules/helpers/shell-helper.fish $args &
    end
end
