#!/bin/fish

function load_modules
    set -g exclude_modules \
        "modules/hakimi_afk.fish"

    set -ge loaded_modules
    set -ge modules_events

    pr_info "modules_loader" "Searching for modules"
    set -g modules (find modules -maxdepth 1 -iname '*.fish')

    pr_info "modules_loader" "Starting to load modules"
    for module in $modules
        set -l exclude_module_continue_marker false
        for excl in $exclude_modules
            if test "$module" = "$excl"
                set exclude_module_continue_marker true
                break
            end
        end
        if test "$exclude_module_continnue_marker" = true
            pr_info "modules_loader" "Skipping module: $module"
            set exclude_module_continue_marker false
            continue
        end

        pr_info "modules_loader" "Loading module: $module"
        set -l old_modules_event $modules_events
        source $module
        if test "$old_modules_event" = "$modules_events"
            pr_warn "modules_loader" "Module $module does not append anything to \$modules_events"
            pr_error "modules_loader" "Failed to load module $module!"
            continue
        end

        set -ga loaded_modules $module
        pr_info "modules_loader" "Loaded: $module"
    end
end

function run_modules
    for event in $modules_events
        emit $event
    end
end

load_modules
