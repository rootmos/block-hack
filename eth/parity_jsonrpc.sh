#!/bin/bash

set -o pipefail

NODE=http://localhost:8545
IPC_SOCKET=${IPC_SOCKET-$PWD/.parity/jsonrpc.ipc}

FAUCET=0x4948653997C1cD1AC7c5D604F09271dEC73C13b1
export FAUCET_PUB=04f4b083594ce3736b48076058d77301b84248453e9c99d7df7038f7ef3e54d43c32010a0a818073a6bcc7c7f42e77647232cb1f89733e735bda3f7ce9a64a50d7

envelope() {
    jq '{jsonrpc: "2.0", id: "'${2-0}'", method: "'$1'", params: .}'
}

send() {
    case ${MODE-HTTP} in
        HTTP) curl -H 'Content-Type: application/json' -X POST --silent -d @- $NODE;;
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
        | hex_to_dec \
        | wei_to_ether
}

kec() {
    keccak-256sum -b -
}

bin_to_hex() {
    xxd -p | tr -d '\n'
}

hex_to_bin() {
    xxd -r -p
}

address_from_pub() {
    echo -n $1 | cut -c3- | hex_to_bin | kec | bin_to_hex | tail -c40
}
