pragma solidity ^0.4.17;

contract SimpleStorage {
    uint myVariable;

    function set(uint x) public {
        myVariable = x + 2;
    }

    function get() constant public returns (uint) {
        return myVariable;
    }
}
