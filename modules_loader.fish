#!/bin/fish

function load_modules -d "Load all modules"
    set -g modules (find modules -maxdepth 1 -iname '*.fish')
    # An array of modules to be excluded,
    # useful for debugging or otherwise modules
    # that's only need to be loaded at a certain time
    set -g modules_exclude \
            "modules/hakimi_afk.fish" \
            "modules/shell.fish"

    set -e loaded_modules
    for module in $modules
        pr_info modules_loader "Loading module: $module"
        for exclude_module in $modules_exclude
            if test "$module" = "$exclude_module"
                pr_warn "Skipping module: $module"
                set -g skip_iter true
                break
            end
        end

        if test "$skip_iter" = true
            set -e skip_iter
            continue
        end

        source "$module"
        set -g loaded_modules $loaded_modules $module
    end
end

function run_modules -d "Run all modules"
    for module in $loaded_modules
        set -l function_name (basename $module)
        set -l function_name (string replace -r '.fish$' '' $function_name)
        $function_name
    end
end

load_modules
