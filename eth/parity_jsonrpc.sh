#!/bin/bash

set -o pipefail

NODE=http://localhost:8545
IPC_SOCKET=${IPC_SOCKET-$PWD/.parity/jsonrpc.ipc}

FAUCET=0x4948653997C1cD1AC7c5D604F09271dEC73C13b1
export FAUCET_PUB=f4b083594ce3736b48076058d77301b84248453e9c99d7df7038f7ef3e54d43c32010a0a818073a6bcc7c7f42e77647232cb1f89733e735bda3f7ce9a64a50d7

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
    hex_to_bin | kec | bin_to_hex | tail -c40
}

tx_hash() {
    ./tx_rlp.py | kec
}

mk_tx() {
    j='{"nounce":"'$1'","gasPrice":"'$GAS_PRICE'",'
    j+='"gasLimit":"'$2'","to":"'$3'",'
    j+='"value":"'$4'","data":"'$5'"}'
    echo -n $j | jq .
}

new_pem_key() {
    openssl ecparam -name secp256k1 -genkey -noout -out $1.pem
}

pub_from_pem() {
    openssl ec -in $1 --pubout -outform DER
}

priv_from_keyfile() {
    password_raw=faucet
    password=$(echo -n $password_raw | base91)
    salt=$(jq -r '.crypto.kdfparams.salt' < $1 | hex_to_bin | base91)
    salt_size=$(jq -r '.crypto.kdfparams.salt' < $1 | hex_to_bin | wc -c)
    N=$(jq -r '.crypto.kdfparams.n' < $1)
    p=$(jq -r '.crypto.kdfparams.p' < $1)
    R=$(jq -r '.crypto.kdfparams.r' < $1)
    size=$(jq -r '.crypto.kdfparams.dklen' < $1)
    derived_key=$(scrypt-kdf --base91-input $password $salt $N $R $p $(calc -p 8*$size) $salt_size | cut -d- -f1 | base91 --decode | bin_to_hex)
    key=$(echo -n $derived_key | head -c32)
    cipher=$(jq -r '.crypto.cipher' < $1)
    iv=$(jq -r '.crypto.cipherparams.iv' < $1)
    jq -r '.crypto.ciphertext' < $1 \
        | hex_to_bin \
        | openssl enc -$cipher -iv $iv -K $key -d \
        | bin_to_hex
}

"$@"
