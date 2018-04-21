#!/usr/bin/env python

import rlp
from rlp.sedes import big_endian_int, binary, List
import json
import sys

j = json.load(sys.stdin)
from pprint import pprint

def L_S(t) : #(Tn, Tp, Tg, Tt, Tv, p) if v ∈ {27, 28}
    fs = [
        int(j["nounce"]),
        int(j["gasPrice"]),
        int(j["gasLimit"]),
        bytes.fromhex(j["to"]),
        int(j["value"]),
        bytes.fromhex(j["data"])]

    list_sedes = List([
        big_endian_int,
        big_endian_int,
        big_endian_int,
        binary,
        big_endian_int,
        binary
        ])

    if "w" in j:
        fs += [int(j["w"]), int(j["r"]), int(j["s"])]
        list_sedes += [big_endian_int, big_endian_int, big_endian_int]
    else:
        fs += [int(j["chain_id"]), bytes.fromhex(""), bytes.fromhex("")]
        list_sedes += [big_endian_int, binary, binary]

    return rlp.encode(fs, list_sedes)

sys.stdout.buffer.write(rlp.encode(L_S(j)))
