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
	"-1001299514785" \
	"-1001155763792"
set -g fwd_to "-1001384382397"
set -g saving_group_id "-1001607510711"
set -g tagger_group_id "-1001530403261"
set -g bot_owner_id "1024853832"
set -g rm6785_update_sticker "CAACAgUAAxkBAAED_CFiFIVi0Z1YX3MOK9xnaylscRhWbQACNwIAAt6sOFUrmjW-3D3-2yME"
