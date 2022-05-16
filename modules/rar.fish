#!/bin/fish

set -g __module_name "Bot log access module (log_dump.fish)"
set -g __module_description "Not relevant to other than bot owner."
set -g __module_version 1
set -g __module_functions rar
set -g __module_help_message "Available commands:
`.unrar` \<Reply to a message\>"

function rar --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.unrar'
            # Make sure we're replying to a file
            if test "$ret_replied_file_id" = null
                tg --replymsg $ret_chat_id $ret_msg_id "Reply to a file please"
                return
            end

            pr_debug rar "Preparing links"
            tg --replymsg $ret_chat_id $ret_msg_id Preparing
            set -l file_path (
            curl -s $API/getFile -d chat_id=$ret_chat_id -d file_id=$ret_replied_file_id |
                jq -r .result.file_path
        )
            set file_path https://api.telegram.org/file/bot$TOKEN/$file_path
            pr_debug rar "file_path: $file_path"

            pr_debug rar "Downloading file"
            tg --editmsg $ret_chat_id $sent_msg_id Downloading

            set -lx TMPDIR /tmp
            set -l start_time (date +%s.%N)
            set -l tmpdir (mktemp -d)
            set -l origpath $PWD
            set -l randfname file-(random).rar

            cd $tmpdir
            aria2c $file_path -o $randfname

            pr_debug rar "Extracting file"
            tg --editmsg $ret_chat_id $sent_msg_id "Extracting"
            pr_debug rar "file: $(basename $randfname)"
            7z e (basename $randfname) &>>$BOT_HOME/logs/debug.log
            or __rar_err_handler

            rm -f $randfname
            pr_debug rar "Uploading files"
            pr_debug rar "Files:
$(ls)"
            tg --editmsg $ret_chat_id $sent_msg_id "Uploading"
            __rar_upload (find -type f)
            __rar_cleanup

            tg --editmsg $ret_chat_id $sent_msg_id "Complete."

            cd $origpath
    end
end

function __rar_err_handler -S
    pr_debug rar "unrar exited with error code: $status"
    tg --editmsg $ret_chat_id $sent_msg_id "Warning: 7z exited with error"
end

function __rar_cleanup -S
    rm -rf $tmpdir
end

function __rar_upload
    for file in $argv
        curl -s $API/sendDocument -F chat_id=$ret_chat_id -F document=@$file &

        while test (jobs | count) -gt 5
            :
        end
    end
    wait
end
