#!/bin/bash

NODE=:8545
FAUCET=0x4948653997C1cD1AC7c5D604F09271dEC73C13b1

envelope() {
    jq '{jsonrpc: "2.0", id: "'${2-0}'", method: "'$1'", params: .}'
}

send() {
    http POST $NODE
}

hex_to_dec() {
    xargs calc -p
}

getBalance() {
    jq -n '["'$1'"]' | envelope eth_getBalance | send | jq -r .result | hex_to_dec
}
