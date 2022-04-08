#!/bin/fish

set -g __module_name "Misc useless stuffs (fun.fish)"
set -g __module_description "RM6785 testing group stuff"
set -g __module_version 1
set -g __module_functions t_msghandler msg_collect loaddb pushdb push_needed t_init
set -g __module_help_message "$__module_description
`.tpushdb` \-\> Push local database
`.tloaddb` \-\> Update local database"

set -g t_gist_link https://gist.github.com/5a6037c3e06f73fb690e3853d2fdccbf

function t_msghandler --on-event modules_trigger
    switch $ret_lowered_msg_text
        case '.tpushdb'
            if not is_botowner
                err_not_botowner
                return
            end
            tg --replymsg $ret_chat_id $ret_msg_id Pushing
            pushdb
            tg --editmsg $ret_chat_id $sent_msg_id Pushed
        case '.tloaddb'
            if not is_botowner
                err_not_botowner
                return
            end
            tg --replymsg $ret_chat_id $ret_msg_id Loading
            loaddb
            tg --editmsg $ret_chat_id $sent_msg_id Loaded
    end
end

function msg_collect --on-event modules_trigger
    if test "$ret_chat_id" = -1001299514785
        pr_debug testing_group "Got message from testing group"
        set -ga t_msgid $ret_msg_id
        set -ga t_msgtext $ret_msg_text
    end

    if push_needed
        pushdb
    end
end

function loaddb
    gh gist view $t_gist_link | source
end

function pushdb
    echo "\
set -g t_msgid $t_msgid
set -g t_msgtext $t_msgtext" | gh gist edit $t_gist_link -
    date +%s >modules/assets/t_metadata
end

function push_needed
    if test (math (cat modules/assets/t_metadata) $t_last_push_time) -gt 3600 # 1hr
        return 0
    else
        return 1
    end
end

function t_init
    pr_info testing_group Initialising
    loaddb
    date +%s >modules/assets/t_metadata
end


# Init when modules is loading
t_init
