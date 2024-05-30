// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DSCoin} from "../src/DSCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    //address dscAddress;

    function run() external returns (DSCoin, DSCEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);

        DSCoin dscoin = new DSCoin();
        DSCEngine engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dscoin));

        dscoin.transferOwnership(address(engine));

        vm.stopBroadcast();

        return (dscoin, engine, helperConfig);
    }
}
