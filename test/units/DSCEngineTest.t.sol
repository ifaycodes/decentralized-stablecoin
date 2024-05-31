// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCoin} from "../../src/DSCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { MockV3Aggregator } from "../mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCoin dscoin;
    DSCEngine dscengine;
    HelperConfig helperConfig;

    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;

    address public USER = makeAddr("USER");
    uint256 public constant AMOUNT_OF_COLLATERAL = 10 ether;
    uint256 amountToMint = 100 ether;

    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;

    function setUp() public {
        deployer = new DeployDSC();
        (dscoin, dscengine, helperConfig) = deployer.run();
        (ethUsdPriceFeed,btcUsdPriceFeed,weth,wbtc,deployerKey) = helperConfig.activeNetworkConfig();

        if (block.chainid == 31337) {
            vm.deal(USER, STARTING_ERC20_BALANCE);
        }
            
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(wbtc).mint(USER, STARTING_ERC20_BALANCE);
    
    }

// constructor
    address[] public tokenAddresses;
    address[] public feedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, feedAddresses, address(dscoin));
    }

    // pricefeed test   
    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dscengine.getUsdValue(weth, ethAmount);

        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        // If we want $100 of WETH @ $2000/WETH, that would be 0.05 WETH
        uint256 expectedWeth = 0.05 ether;
        uint256 amountWeth = dscengine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(amountWeth, expectedWeth);
    }

    //deposit tests
    function testRevertsIfSendsZero() public {

        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscengine), AMOUNT_OF_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscengine.depositCollateral(weth, 0);

        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock("RAN", "RAN", USER, 100e18);
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__NotAllowedToken.selector, address(randToken)));
        dscengine.depositCollateral(address(randToken), AMOUNT_OF_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscengine), AMOUNT_OF_COLLATERAL);
        dscengine.depositCollateral(weth, AMOUNT_OF_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralWithoutMinting() public depositedCollateral {
        uint256 userBalance = dscoin.balanceOf(USER);
        assertEq(userBalance, 0);
    }

    function testCanDepositedCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscengine.getAccountInformation(USER);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositedAmount = dscengine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        console.log("totalDscMinted:", totalDscMinted);
        console.log("collateralValueInUsd:", collateralValueInUsd);
        console.log("expectedDepositedAmount:", expectedDepositedAmount);
        console.log("AMOUNT_OF_COLLATERAL:", AMOUNT_OF_COLLATERAL);

        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(expectedDepositedAmount, AMOUNT_OF_COLLATERAL);
    } 

    //depositCollateralAndMintDsc tests
    function testRevertsIfMintedDscBreaksHealthFactor() public {
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        amountToMint = (AMOUNT_OF_COLLATERAL * (uint256(price) * dscengine.getAdditionalFeedPrecision())) / dscengine.getPrecision();
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscengine), AMOUNT_OF_COLLATERAL);

        uint256 expectedHealthFactor =
            dscengine.calculateHealthFactor(amountToMint, dscengine.getUsdValue(weth, AMOUNT_OF_COLLATERAL));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreakingHealthFactor.selector, expectedHealthFactor));
        dscengine.depositCollateralAndMintDsc(weth, AMOUNT_OF_COLLATERAL, amountToMint);
        vm.stopPrank();
    }

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscengine), AMOUNT_OF_COLLATERAL);
        dscengine.depositCollateralAndMintDsc(weth, AMOUNT_OF_COLLATERAL, amountToMint);
        vm.stopPrank();
        _;
    }

    function testCanMintWithDepositedCollateral() public depositedCollateralAndMintedDsc {
        uint256 userBalance = dscoin.balanceOf(USER);
        assertEq(userBalance, amountToMint);
    }

    //burnDsc test
    function testRevertsIfBurnAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscengine), AMOUNT_OF_COLLATERAL);
        dscengine.depositCollateralAndMintDsc(weth, AMOUNT_OF_COLLATERAL, amountToMint);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscengine.burnDsc(0);
        vm.stopPrank();
    }

    function testCantBurnMoreThanUserHas() public {
        vm.prank(USER);
        vm.expectRevert();
        dscengine.burnDsc(1);
    }

    function testCanBurnDsc() public depositedCollateralAndMintedDsc {
        vm.startPrank(USER);
        dscoin.approve(address(dscengine), amountToMint);
        dscengine.burnDsc(amountToMint);
        vm.stopPrank();

        uint256 userBalance = dscoin.balanceOf(USER);
        assertEq(userBalance, 0);
    }
}
