CURRENT_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

KEYS_PATH := $(CURRENT_DIR)/keys

PARITY := parity
PARITY_BASE := $(CURRENT_DIR)/.parity
PARITY_UNLOCK := --unlock 0x$(shell jq -r .address keys/faucet.json) --password=keys/faucet.password
PARITY_OPTS := --port 0 --reserved-peers ./peers --base-path=$(PARITY_BASE) --chain $(CURRENT_DIR)/dev-chain.json $(PARITY_UNLOCK) --jsonrpc-cors http://localhost --reseal-min-period 0
ETHKEY := ethkey

run: faucet
	$(PARITY) $(PARITY_OPTS)

ui: faucet
	$(PARITY) $(PARITY_OPTS) ui

faucet: $(KEYS_PATH)/faucet.json
	$(PARITY) $(PARITY_OPTS) account import $<

new-account:
	$(PARITY) $(PARITY_OPTS) account new

$(KEYS_PATH)/%.json:
	$(ETHKEY) generate $@

clean:
	rm -rf $(PARITY_BASE)

PYTHON_DEPENDENCIES := requirements.txt.flag
$(PYTHON_DEPENDENCIES): requirements.txt
	pip install --user -r $<
	touch $@

dependencies: $(PYTHON_DEPENDENCIES)

geth:
	geth --datadir=geth-data init genesis.json
	nice geth --rpc --nodiscover --networkid=66 \
	   --datadir=geth-data \
	   --etherbase=0x0000000000000000000000000000000000000002 \
	   --unlock $(shell jq -r .address keys/faucet.json) --password keys/faucet.password \
	   --dev.period 0 \
	   --mine --minerthreads=1 \
	   console

.PHONY: run ui faucet-key clean new-account dependencies geth

