#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

if [[ "${1-}" =~ ^-*h(elp)?$ ]] || [[ $# -eq 0 ]]; then
    echo 'Usage: ./build-iso.sh MACHINE [NAME]

Build raw-efi image based on MACHINE (see flake.nix)

Optionally supply a name. If name is not supplied, then the machine name will be set to MACHINE.

'
    exit
fi

cd "$(dirname "$0")"

main() {
    MACHINE=$1
    if [[ $# -gt 1 ]]; then
        NAME=$2
    else
        NAME=$1
    fi


    osascript -- - "$MACHINE" "$NAME" <<END
        on run argv
           tell application "UTM"
               set disk to ("/Users/sebastian/Code/laboratorium/results/" & item 1 of argv & ".img")
               set vm to make new virtual machine with properties { backend:qemu, configuration: { name:item 2 of argv, architecture:"aarch64", drives: {{removable:false, source:disk}}}}
           end tell
       end run
END
    chmod 755 /Users/sebastian/Library/Containers/com.utmapp.UTM/Data/Documents/"$NAME".utm/Data/efi_vars.fd

    utmctl start "$NAME"

    until (utmctl ip-address "$NAME" 2>/dev/null | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
    do
        echo "Waiting for machine $NAME to start..."
        sleep 10
    done
}


main "$@"