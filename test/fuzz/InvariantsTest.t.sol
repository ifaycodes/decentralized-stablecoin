// SPDX-License-Identifier: MIT

// What are the invariants

// - total supply of DSC should always be less then collateral
// - getter view functions should never revert -> evergreen invariant

 
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCoin} from "../../src/DSCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract Invariants is StdInvariant, Test {
    DeployDSC deployer;
    DSCoin dscoin;
    DSCEngine dscengine;
    HelperConfig helperConfig;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address weth;
    address wbtc;
    
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dscoin, dscengine, helperConfig) = deployer.run();

        (ethUsdPriceFeed,btcUsdPriceFeed,weth,wbtc,) = helperConfig.activeNetworkConfig();
        handler = new Handler(dscengine, dscoin);
        targetContract(address(handler));
    }

    function invariant_protocolShouldMustHaveMoreCollateralThanTotalDscSupply() public view {
        //get the value of all the collateral in the protocol and compare to total dsc(debt)

        uint256 totalSupply = dscoin.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscengine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscengine));

        uint256 wethValue = dscengine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dscengine.getUsdValue(wbtc, totalWbtcDeposited);

        assert (wethValue + wbtcValue > totalSupply);
    }
}