#!/bin/fish

set -g __module_name "ADB logs (log.fish)"
set -g __module_description "Easily take logs from telegram"
set -g __module_version 69
set -g __module_functions log "log.for.five.sec" "log.purge" "log.upload" "log.gen.gist" "log.editmsg" "log.date" "log.scrub.gist"
set -g __module_help_message "Irrelevant to other than bot owner\. Available commands:
`.log logtype` \-\> Take ADB logcat\."

function log --on-event modules_trigger
    log.scrub.gist
    switch $ret_lowered_msg_text
        case '.log*'
            if not is_botowner
                err_not_botowner
            end
            set -l log_type (string replace -r '.log ' '' $ret_lowered_msg_text)
            rm -f $HOME/logs/adb_logcat.txt
            rm -f $HOME/logs/adb_logcat_all.txt
            rm -f $HOME/logs/adb_logcat_radio.txt

            log.for.five.sec $log_type
    end
end

function log.for.five.sec
    set -l log_type $argv[1]
    set -g n \n
    if test "$log_type" = .log
        set log_type normal
    end
    tg --replymarkdownv2msg $ret_chat_id $ret_msg_id "Progress$n"
    set -ga log_progress "Progress$n"
    set -l date (log.date)
    set -ga log_progress "`$date` \\- Waiting for device$n"
    log.editmsg
    adb wait-for-device
    set date (log.date)
    set -ga log_progress "`$date` \\- Taking log \\| type: $log_type$n"
    log.editmsg

    set -l file_name
    switch $log_type
        case all
            set file_name "$HOME/logs/adb_logcat_all.txt"
            adb logcat -b all >$file_name &
        case radio
            set file_name "$HOME/logs/adb_logcat_radio.txt"
            adb logcat -b radio >$file_name &
        case '*'
            set file_name "$HOME/logs/adb_logcat.txt"
            adb logcat >$file_name &
    end
    sleep 5
    kill $last_pid

    log.purge $file_name
end

function log.purge
    set -l file_name $argv[1]

    set -l date (log.date)
    set -ga log_progress "`$date` \\- Purging AutoPasteSuggestionHelper \\(contains clipboard content\\)$n"
    log.editmsg
    sed -i /AutoPasteSuggestionHelper/d $file_name
    log.upload $file_name
end

function log.upload
    set -l file_name $argv[1]
    set -l esc_file_name (string replace '.' '\\.' $file_name)
    set -l esc_file_name (string replace '_' '\\_' $esc_file_name)

    set -l date (log.date)
    set -ga log_progress "`$date` \\- Uploading $esc_file_name$n"
    log.editmsg
    curl $API/sendDocument -F chat_id=$ret_chat_id -F document=@$file_name
    log.gen.gist $file_name
end

function log.gen.gist
    set -l file_name $argv[1]

    set -l date (log.date)
    set -ga log_progress "`$date` \\- Creating gist$n"
    log.editmsg
    set -l log_url (gh gist create < $file_name | tail -n1)
    set -l date (log.date)
    set -l esc_log_url (string replace -a '.' '\\.' $log_url)
    set -ga log_progress "`$date` \\- gist link: $esc_log_url$n"
    log.editmsg
    echo $log_url >>~/.gist_markers # Old gist will be deleted by log.scrub.gist once it exceeds 30
end

function log.editmsg
    curl -s $API/editMessageText \
        -d chat_id=$ret_chat_id \
        -d message_id=$sent_msg_id \
        -d text=$log_progress \
        -d parse_mode=MarkdownV2 \
        -d disable_web_page_preview=true
end

function log.date
    date +%H:%M:%S
end

function log.scrub.gist
    set -l gist_line_count (wc -l < ~/.gist_markers)
    if test "$gist_line_count" -gt 30
        pr_info log "Gist used for adb log exceeds 30, deleting oldest gist"
        set -l oldest_gist (head -n1 ~/.gist_markers)
        gh gist delete $oldest_gist
        sed -i 1d ~/.gist_markers
    end
end
