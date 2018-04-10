#!/bin/bash

set -o pipefail

NODE=:8545
IPC_SOCKET=${IPC_SOCKET-$PWD/.parity/jsonrpc.ipc}

FAUCET=0x4948653997C1cD1AC7c5D604F09271dEC73C13b1

envelope() {
    jq '{jsonrpc: "2.0", id: "'${2-0}'", method: "'$1'", params: .}'
}

DEFAULT_MODE=IPC

send() {
    case ${MODE-$DEFAULT_MODE} in
        HTTP) http POST $NODE;;
        IPC) socat - UNIX-CONNECT:$IPC_SOCKET;;
    esac
}

hex_to_dec() {
    xargs calc -p
}

wei_to_ether() {
    xargs -I{} calc -p '{}/10^18'
}

handle_response() {
    jq -r 'if has("error") then error(.error.message) else .result end'
}

getBalance() {
    jq -n '["'$1'"]' \
        | envelope eth_getBalance \
        | send | handle_response \
        | hex_to_dec
}
