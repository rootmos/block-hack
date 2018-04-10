CURRENT_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

KEYS_PATH := $(CURRENT_DIR)/keys

PARITY := parity
PARITY_BASE := $(CURRENT_DIR)/.parity
PARITY_OPTS := --base-path=$(PARITY_BASE) --chain $(CURRENT_DIR)/dev-chain.json
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

.PHONY: run ui faucet-key clean new-account
