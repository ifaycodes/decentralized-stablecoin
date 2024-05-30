// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/*
* @author Ifeoma
* @title DecentralizedStableCoin
*/

import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract DSCoin is ERC20Burnable, Ownable {

    error DSCoin__MustBeMoreThanZero();
    error DSCoin__BurnAmountMustExceedBalance();
    error DSCoin__NotZeroAddress();


    constructor() ERC20("DSCoin", "DSC") Ownable(msg.sender) {}

    function burn (uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DSCoin__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DSCoin__BurnAmountMustExceedBalance();
        }

        super.burn(_amount);
    }

    function mint (address _to, uint256 _amount) external onlyOwner returns(bool) {
        if (_to == address(0)) {
            revert DSCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DSCoin__MustBeMoreThanZero();
        }

        _mint(_to, _amount);

        return true;
    }
}
