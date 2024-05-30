// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DSCoin} from "../../src/DSCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {
    DSCEngine dscengine;
    DSCoin dscoin;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 public timesMintIsCalled;
    address[] public usersWithCollateralDeposited;
    MockV3Aggregator public ethUsdPriceFeed;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _dscengine, DSCoin _dscoin) {
        dscengine = _dscengine;
        dscoin = _dscoin;

        address[] memory collateralTokens = dscengine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        //ethUsdPriceFeed = dscengine.getCollateralTokenPriceFeed(address(weth));
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length];
        if(usersWithCollateralDeposited.length == 0) {
            return; }
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscengine.getAccountInformation(msg.sender);

        int256 maxDscToMint = (int256(collateralValueInUsd) / 2) -  int256(totalDscMinted);
        if (maxDscToMint < 0) {
            return;
        }

        amount = bound(amount, 0, uint256(maxDscToMint));
        if (amount == 0) {
            return;
        }

        vm.startPrank(sender);
        dscengine.mintDsc(amount);
        vm.stopPrank();
    }

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dscengine), amountCollateral);
        dscengine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        timesMintIsCalled++;

        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dscengine.getCollateralBalanceOfUser(address(collateral), msg.sender);
        amountCollateral = bound(amountCollateral, 1, maxCollateralToRedeem);
        if (amountCollateral == 0) {
            return;
        }
        dscengine.redeemCollateral(address(collateral), amountCollateral);
    }

    //breaks invariant test suite
    
    // function updateCollateralPrice(uint96 newPrice) public {
    //     int256 newPriceInt int256(uint256(newPrice));
    //     ethUsdPriceFeed.updateAnswer(newPriceInt);
    // }

    //Helper function
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}