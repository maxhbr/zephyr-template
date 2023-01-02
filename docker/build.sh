#!/usr/bin/env bash
set -euo pipefail

oci_cmd=docker

oci_build() {
    $oci_cmd build "$context" --tag "$tag"
}

oci_west() (
    set -x
    $oci_cmd run --rm -it \
        --user user:user \
        -v "${repo}:/workspaces/${path}" \
        --workdir="/workspaces/${path}" \
        -e path="${path}" \
        "$tag" \
        west $@
)

main() {
    if [[ $# -gt 0 && "$1" == "--only-native-init" ]]; then
        [[ -d ".west" ]] || west init -l "$path"
        west update #-f always
        west config -l
        west zephyr-export
    else
        context="$( cd -- "$( dirname -- "$(readlink -f "${BASH_SOURCE[0]}")" )" &> /dev/null && pwd )"
        repo="$(readlink -f "${context}/..")"
        path="$(cat "$repo/west.yml" | yq -r '.manifest.self.path')"
        tag="maxhbr/${path}-zephyrbuilder"

        if [[ $# -gt 0 && "$1" == "--build" ]]; then
            shift
            oci_build
        fi

        [[ -d ".west" ]] || oci_west init -l "$path"
        oci_west update #-f always
        oci_west config -l
        oci_west zephyr-export
        oci_west build \
            -s "." \
            -p always \
            -d ./build
    fi
}

main $@