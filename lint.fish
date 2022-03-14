#!/bin/fish

read -n1 -p "echo -n 'This script will pass all script through fish_indent. Do you want to continue?[y/N]: '" prompt

if test (string lower $prompt) != y
    exit 0
end

set_color -b brmagenta
set_color black
echo -ne "\rProceeding"
for col in (seq (math $COLUMNS - (string split '' "Proceeding" | count)))
    echo -n ' '
end
set_color normal

set scripts (find -type f -iname '*.fish')
set scripts (string split ' ' $scripts)

for script in $scripts
    set_color brblue
    echo "PASSING: $script"
    set_color normal
    fish_indent -w $script
end
