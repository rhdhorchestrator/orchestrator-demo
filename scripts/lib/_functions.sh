#!/usr/bin/env bash

function is_macos {
    [[ "$(uname)" == "Darwin" ]]
}

# A wrapper for the find command that uses the -E flag on macOS.
# Extended regex (ERE) is not supported by default on macOS.
function findw {
    if is_macos; then
        find -E "$@"
    else
        find "$@"
    fi
}

function get_workflow_id {
    local workdir=${1:-$PWD}
    local workflow_file=""
    local workflow_id=""

    workflow_file=$(findw "$workdir" -type f -regex '.*\.sw\.ya?ml$')
    if [ -z "$workflow_file" ]; then
        echo "ERROR: No workflow file found with *.sw.yaml or *.sw.yml suffix"
        return 10
    fi

    workflow_id=$(yq '.id | downcase' "$workflow_file" 2>/dev/null)
    if [ -z "$workflow_id" ]; then
        echo "ERROR: The workflow file doesn't seem to have an 'id' property."
        return 11
    fi

    echo "$workflow_id"
}

function pocker {
    $(command -v podman || command -v docker) "$@"
}
