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

blockNumber() {
    jq -n '[]' | envelope eth_blockNumber | send | handle_response
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

mk_unsigned_tx() {
    j='{"nounce":"'$NOUNCE'","gasPrice":"'$GAS_PRICE'",'
    j+='"gasLimit":"'$GAS_LIMIT'","to":"'$TO'",'
    j+='"value":"'$VALUE'","data":"'$DATA'",'
    j+='"chain_id":"'$(chain_id)'"}'
    echo -n $j | jq .
}

mk_signed_tx() {
    j='{"nounce":"'$NOUNCE'","gasPrice":"'$GAS_PRICE'",'
    j+='"gasLimit":"'$GAS_LIMIT'","to":"'$TO'",'
    j+='"value":"'$VALUE'","data":"'$DATA'",'
    j+='"r":"'$R'","s":"'$S'", "w":"'$W'"}'
    echo -n $j | jq .
}

new_pem_key() {
    openssl ecparam -name secp256k1 -genkey -noout -out $1.pem
}

pub_from_pem() {
    openssl ec -in $1 --pubout -outform DER
}

priv_from_keyfile() {
    password=$(echo -n $2 | base91)
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

priv_to_pem() {
    hex_to_bin | asn/convert | openssl ec -inform der -outform pem -out $1
}

ecsign() {
    openssl dgst -sha256 -binary -sign $1
}

T_r() {
    head -c32
}

T_s() {
    tail -c+33 | head -c32
}

bin_to_dec() {
    bin_to_hex | sed 's/^/0x/' | hex_to_dec
}

chain_id() {
    cat ${CHAIN-dev-chain.json} | jq -r .params.chainId | hex_to_dec
}

sign() {
    export NOUNCE=$1
    export GAS_PRICE=$2
    export GAS_LIMIT=$3
    export TO=$4
    export VALUE=$5
    export DATA=$6
    export UTX_HASH=$(mk_unsigned_tx | tx_hash | bin_to_hex)
    export SIG=$(echo $UTX_HASH | hex_to_bin | ecsign $7 | bin_to_hex)
    export R=$(echo $SIG | hex_to_bin | T_r | bin_to_dec)
    export S=$(echo $SIG | hex_to_bin | T_s | bin_to_dec)
    export W=$(calc -p $(chain_id)*2+35)
    mk_signed_tx
}

send_tx() {
    read tx
    jq -n '["0x'$tx'"]' \
        | envelope eth_sendRawTransaction \
        | send | handle_response
}

"$@"
