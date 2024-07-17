// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Test, console} from "forge-std/Test.sol";
import {TokenPermit} from "src/TokenPermit.sol";
import {TokenBank} from "src/TokenBank.sol";
import {SigUtils} from "./SignTypedData.sol";

contract TokenBankTest is Test {

        struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    SigUtils internal sigUtils;
    TokenPermit public token;
    TokenBank public bank;
    using ECDSA for bytes32;

    function setUp() public {

        token = new TokenPermit("HotPotDevil", "HPD");
        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());
        bank = new TokenBank(address(token));

    }
    // function test_deposit(address _depositAddress,uint _depositAmount) public {

    //     vm.assume(_depositAmount > 0.001*1E18);
    //     vm.assume(_depositAmount < 10000*1E18);
    //     vm.assume(_depositAddress != address(0));

    //     token.transfer(_depositAddress, _depositAmount);

    //     vm.startPrank(_depositAddress);
    //     token.approve(address(bank), _depositAmount);
    //     bank.deposit(_depositAmount);
    //     vm.stopPrank();

    //     assertEq(bank.AddressToAmount(_depositAddress), _depositAmount);

    // }


    function test_Permit(uint160 _ownerPrivateKey,uint _depositAmount) public {

        vm.assume(_ownerPrivateKey != 0);
        vm.assume(_depositAmount > 0.001*1E18);
        vm.assume(_depositAmount < 1000*1E18);

        address  depositAddress = vm.addr(_ownerPrivateKey);
        token.transfer(depositAddress, _depositAmount);

        assertEq(bank.getBalance(depositAddress), 0);

        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: depositAddress,
            spender: address(bank),
            value: _depositAmount,
            nonce: vm.getNonce(depositAddress), 
            deadline: 10 minutes
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_ownerPrivateKey, digest);

        bank.permitDeposit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        assertEq(bank.getBalance(depositAddress), _depositAmount);
    }

    
    }

