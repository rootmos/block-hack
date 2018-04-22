const SimpleStorage = artifacts.require("SimpleStorage");

contract("SimpleStorage", async (accounts) => {
    it("should store and retrieve a number", async () => {
        let storage = await SimpleStorage.deployed();
        let _ = await storage.set(18);
        let res = await storage.get();
        assert.equal(res.valueOf(), 20, "20 wasn't returned");
    });
})
