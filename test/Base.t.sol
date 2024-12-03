// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {Test, Vm, console2} from "forge-std/src/Test.sol";

import {TwoCryptoNGPrecompiles, TwoCryptoFactory, TwoCryptoNGParams} from "./TwoCryptoNGPrecompiles.sol";
import {MockERC20} from "./MockERC20.sol";

import {ITwoCrypto} from "src/ITwoCrypto.sol";

abstract contract Base is Test {
    address admin = makeAddr("admin");
    address alice = makeAddr("alice");

    MockERC20 target;
    MockERC20 pt;
    address factory;
    ITwoCrypto twoCrypto;
    uint256 bOne;
    uint256 tOne;

    TwoCryptoNGParams params = TwoCryptoNGParams({
        A: 40000000, // 0 unit
        gamma: 0.019 * 1e18, // 1e18 unit
        mid_fee: 0.0006 * 1e8, // 1e8 unit
        out_fee: 0.006 * 1e8, // 1e8 unit
        fee_gamma: 0.07 * 1e18, // 1e18 unit
        allowed_extra_profit: 2e-6 * 1e18, // 1e18 unit
        adjustment_step: 0.00049 * 1e18, // 1e18 unit
        ma_time: 3600, // 0 unit
        initial_price: 0.7e18 // price of the coins[1] against the coins[0] (1e18 unit)
    });

    function setUp() public virtual {
        target = new MockERC20(18);
        pt = new MockERC20(18);
        bOne = 18;
        tOne = 18;

        _deployTwoCrypto();

        // Principal Token should be discounted against underlying token
        uint256 initialPrincipal = 1_700_000 * 10 ** tOne;
        uint256 initialShares = 1_000_000 * 10 ** tOne;

        // Setup initial AMM liquidity
        setUpAMM(AMMInit({user: alice, share: initialShares, principal: initialPrincipal}));
    }

    struct AMMInit {
        address user;
        uint256 share;
        uint256 principal;
    }

    function setUpAMM(AMMInit memory init) public {
        address user = init.user;
        // principals
        uint256 principal = init.principal;
        try pt.mint(user, principal) {}
        catch {
            vm.assume(false);
        }

        // shares
        uint256 shares = init.share;
        try target.mint(user, shares) {}
        catch {
            vm.assume(false);
        }

        // LP tokens
        vm.startPrank(user);
        target.approve(address(twoCrypto), type(uint256).max);
        pt.approve(address(twoCrypto), type(uint256).max);
        try ITwoCrypto(address(twoCrypto)).add_liquidity([shares, principal], 0, user) {}
        catch {
            vm.assume(false);
        }
        vm.stopPrank();
    }

    struct SetupAMMFuzzInput {
        uint256[2] deposits;
        uint256 timestamp;
    }
    // int256 yield;

    modifier boundSetupAMMFuzzInput(SetupAMMFuzzInput memory input) virtual {
        uint256 price = twoCrypto.last_prices(); // coin1 price in terms of coin0 in wei
        input.deposits[1] = bound(input.deposits[1], 1e6, 1_000 * 10 ** tOne);
        input.deposits[0] = bound(input.deposits[0], 0, input.deposits[1] * price / 1e18);
        input.timestamp = bound(input.timestamp, block.timestamp, 10 days);
        // input.yield = bound(input.yield, -1_000 * int256(bOne), int256(1_000 * bOne));
        _;
    }

    modifier fuzzAMMState(SetupAMMFuzzInput memory input) {
        address fujiwara = makeAddr("fujiwara");
        vm.warp(input.timestamp);
        this.setUpAMM(AMMInit({user: fujiwara, share: input.deposits[0], principal: input.deposits[1]}));
        // this.setUpYield(input.yield);
        _;
    }

    function _deployTwoCrypto() internal {
        address math = TwoCryptoNGPrecompiles.deployMath();
        address views = TwoCryptoNGPrecompiles.deployViews();
        address amm = TwoCryptoNGPrecompiles.deployBlueprint();

        vm.startPrank(admin, admin);
        factory = TwoCryptoNGPrecompiles.deployFactory();

        vm.label(math, "twocrypto_math");
        vm.label(views, "twocrypto_views");
        vm.label(amm, "twocrypto_blueprint");

        TwoCryptoFactory(factory).initialise_ownership(admin, admin);
        TwoCryptoFactory(factory).set_pool_implementation(amm, 0);
        TwoCryptoFactory(factory).set_views_implementation(views);
        TwoCryptoFactory(factory).set_math_implementation(math);

        twoCrypto = ITwoCrypto(
            TwoCryptoNGPrecompiles.deployTwoCrypto(
                factory, "twoCryptoNG", "twoCryptoNG", [address(target), address(pt)], 0, params
            )
        );
        vm.stopPrank();
    }
}

contract TwoCryptoTest is Base {
    function testDebug() external {
        // TwoCryptoTest::testFuzz_Exchange
        bytes memory data =
            hex"5357ddbf0000000000000000000000000000000000000000000000000000000000000a0a00000000000000000000000000000000000000000000000000000000000017880000000000000000000000000000000000000000000000000000000000001bfd0000000000000000000000000000000000000000000000000000000000001601";
        (bool s, bytes memory ret) = address(this).call(data);
        require(s, "testDebug failed");
    }

    function testFuzz_Exchange(SetupAMMFuzzInput memory input, uint256 dx)
        public
        boundSetupAMMFuzzInput(input)
        fuzzAMMState(input)
    {
        // Ignore the case where the preview fails.
        (bool s1, bytes memory ret1) = address(twoCrypto).staticcall(abi.encodeCall(twoCrypto.get_dy, (0, 1, dx)));
        vm.assume(s1);
        uint256 preview = abi.decode(ret1, (uint256));

        target.mint(alice, dx);
        vm.prank(alice);
        (bool s2, bytes memory ret2) = address(twoCrypto).call(abi.encodeCall(twoCrypto.exchange, (0, 1, dx, 0, alice)));

        assertTrue(s2, "Preview succeded but exchange failed");

        uint256 result = abi.decode(ret2, (uint256));
        assertEq(result, preview, "result != preview");
    }
}
