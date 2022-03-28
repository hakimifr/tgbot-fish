# modules
Modules are located here. They are unloadable making them superiour because I am free to unload module that I don't need at any time.

- At the top of the module, it must define these variables: 
    - __module_name
    - __module_description
    - __module_version
    - __module_functions
    - __module_help_message

otherwise modules loader will refuse to load them.
- They **must** also respond to emitted *`modules_trigger`* whenever modules is ran.
- A module functions in __module_functions **must** properly be listed, especially one that respond to *`modules_trigger`* event. Otherwise it wouldn't be unloaded correctly.
- __module_help_message **must** escape characters that are not allowed by Telegram API's MarkdownV2. Bold, italics and monospace may be used here.
- Below is an example module:
```fish
#!/bin/fish

set -g __module_name "Sample Module"
set -g __module_description "This module does nothing"
set -g __module_version 1
set -g __module_functions function_one function_two
set -g __module_help_message "This is the help message for a dummy module\."

function function_one --on-event modules_trigger
    echo "I am called!"
end

function function_two
    # Dummy function
    true
end
```
