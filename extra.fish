#!/bin/fish


function round -d "round a number"
    if test (count $argv) -ne 2
        echo "Invalid amount of arguements!" >&2
        return 1
    end
    set -l float $argv[1]
    set -l decimal_point $argv[2]
    printf "%.{$decimal_point}f" $float
end

set -g fwd_approved_chat_id \
    -1001299514785 \
    -1001155763792
set -g fwd_auth_user $bot_owner_id (command cat modules/assets/rm6785_auth_user)
set -g fwd_to -1001384382397
set -g saving_group_id -1001607510711
set -g tagger_group_id -1001530403261
set -g bot_owner_id 1024853832
set -g rm6785_update_sticker CAACAgUAAxkBAAED_CFiFIVi0Z1YX3MOK9xnaylscRhWbQACNwIAAt6sOFUrmjW-3D3-2yME
set -g help_message '`.calc` \-\> Do math calculations
`.magisk` \-\> Get latest magisk stable and canary
`.save` \(bot owner only\) \-\> Save message
`.help`, `/help` \-\> View this help message
`.test`, `/test` \-\> Check if the bot is running
`.save` \(bot owner only\) \-\> Forward message to saving group

Note: This list is incomplete\. Each modules have their own help message and you can view them individually\. List all loaded modules with `.lsmod` and view their help message with `.modhelp modulename.fish`\.'
