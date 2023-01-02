#!/usr/bin/env bash
set -euo pipefail

oci_cmd=docker

oci_build() {
    local tag="$1"; shift
    local context="$1"; shift
    $oci_cmd build "$context" --tag "$tag"
}

oci_west() (
    local tag="$1"; shift
    local repo="$1"; shift
    local path="$1"; shift

    set -x
    $oci_cmd run --rm -it \
        --user user:user \
        -v "${repo}:/workspaces/${path}" \
        --workdir="/workspaces/${path}" \
        "$tag" \
        west $@
)

main() {
    local context="$( cd -- "$( dirname -- "$(readlink -f "${BASH_SOURCE[0]}")" )" &> /dev/null && pwd )"
    local repo="$(readlink -f "${context}/..")"

    if [[ $# -gt 0 && "$1" == "--only-native-init" ]]; then
        [[ -d ".west" ]] || west init
        west update --narrow #-f always
        west blobs fetch hal_espressif
        west config -l
        west zephyr-export
    else
        local path="$(cat "${repo}/west.yml" | yq -r '.manifest.self.path')"
        local tag="maxhbr/${path}-zephyrbuilder"

        if [[ $# -gt 0 && "$1" == "--build" ]]; then
            shift
            oci_build "${tag}" "${context}"
        fi

        [[ -d ".west" ]] || oci_west "${tag}" "${repo}" "${path}" init
        oci_west "${tag}" "${repo}" "${path}" \
            update --narrow #-f always
        oci_west "${tag}" "${repo}" "${path}" \
            blobs fetch hal_espressif
        oci_west "${tag}" "${repo}" "${path}" \
            config -l
        oci_west "${tag}" "${repo}" "${path}" \
            zephyr-export
        oci_west "${tag}" "${repo}" "${path}" \
            build \
            -s "." \
            -p always \
            -d ./build
    fi
}

main $@