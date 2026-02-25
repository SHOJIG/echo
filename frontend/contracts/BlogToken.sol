// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BlogToken is ERC20 {
    constructor() ERC20("BlogToken", "BLG") {
        _mint(msg.sender, 10**18);
    }
}