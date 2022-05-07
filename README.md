# tgbot-fish
Previous [tgbot](https://github.com/Hakimi0804/tgbot) is rewritten in fish. It is depracated.

[![Deploy to heroku.](https://github.com/Hakimi0804/tgbot-fish/actions/workflows/docker-heroku.yml/badge.svg)](https://github.com/Hakimi0804/tgbot-fish/actions/workflows/docker-heroku.yml)

## Files and Folders in This Repo
```
README.md               # This file
tgbot.fish              # Main script
extra.fish              # Configuration and extra functions/init stuff
util.fish               # Contains mandatory functions
modules_loader.fish     # Loads modules
modules/                # Contains extension to this bot
```

## Breaking Down Each Files
---
### tgbot.fish
- Contains a while loop, calls for function `update_init`, `update`.
- These functions are defined in `util.fish`, more about it later.
- Contains commands that you don't care about being unloadable, because I can't when putting commands here.

### extra.fish
- Contains extra variables or functions that are not fitting in util.
- Also contains help message text.

### util.fish
- Contains mandatory variables for this bot.
- Contains mandatory and semi-mandatory functions for this bot of which are (not limited to, but including):
    - `update_init` -- Get initial update ID, so `update` can function properly.
    - `update` -- Update received message, etc so you can process them with your modules/whatever you put in tgbot.fish.
    - `tg` -- Send message, reply, delete messages, etc
    - `pr_info` -- print a message with green colour and a capitalized text indicating INFO.
    - `pr_debug` -- Same as above but with magenta colour and a capitalized DEBUG text.
    - `pr_warn` -- Same as above but with yellow colour and a capitalized WARN text.
    - `pr_error` -- Same as above but with red colour and a capitalized ERROR text.

### modules_loader.fish
- Loads modules from the modules/ directory.
- Contains functions of which are (including, but not limited to):
    - `__module_load` -- Load a given module.
    - `__module_unload` -- Unload a given module.
    - `load_modules` -- Search `modules/` directory with a max depth of 1 and load found modules.
    - `run_modules` -- Emit `modules_trigger` event. Each modules must have at least one function responding to this even if it wants to do something. Sample function:
    ```fish
    function foo --on-event modules_trigger
        echo "I am called!"
    end
    ```
    - For more info regarding modules checkout [modules readme](modules/README.md)
