// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, ERC20Burnable, Ownable {
    // state vars
    uint256 private _totalSupply;

    // *************************************************************************
    // FUNCTIONS

    constructor()
        ERC20("Kingdom Token", "KT")
        Ownable(msg.sender)
    {
        _totalSupply = 1000*10**6 * 10**18;
        mint(msg.sender, _totalSupply);
    }

    // *************************************************************************
    // MINING FUNCTIONS

    /// @notice This function allows for the minting of ERC20 tokens.
    /// @dev Can only be called by the current owner of the contract.
    /// @param to The address that will receive the minted tokens.
    /// @param amount The number of tokens to mint.
    function mint(
        address to,
        uint256 amount
    )
        public
        onlyOwner
    {
        _mint(to, amount);
    }
}
