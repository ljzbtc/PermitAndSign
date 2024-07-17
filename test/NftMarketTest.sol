// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Test, console} from "forge-std/Test.sol";
import {TokenPermit} from "src/TokenPermit.sol";
import {NftMarket} from "src/NftMarket.sol";
import {Sunday721} from "src/Sunday.sol";
import {SigUtils_nftmarket} from "./SignNtfmarketTypedData.sol";

contract NftMarketTest is Test {
    using ECDSA for bytes32;

    struct Nft_witheList {
        address wallet;
    }

    SigUtils_nftmarket internal sigUtils_nftmarket;
    NftMarket public nftMarket;
    TokenPermit public token;
    Sunday721 public nft;
    
    uint public tokenID;
    uint160 private nftownerPrivateKey;
    address private nftOwnerAddress;

    function setUp() public {
        nftownerPrivateKey = 0x11;
        nftOwnerAddress = vm.addr(nftownerPrivateKey);

        token = new TokenPermit("HotPotDevil", "HPD");
        nftMarket = new NftMarket(address(token), nftOwnerAddress);
        sigUtils_nftmarket = new SigUtils_nftmarket(nftMarket.DOMAIN_SEPARATOR());
        nft = new Sunday721();
        
        tokenID = 0;
        nft.mint(address(this), tokenID);
    }

    function test_verfiy_buy(address buyer) public {
        
        uint price = 1000;
        vm.assume(buyer != address(0));

        assertNotEq(nft.ownerOf(tokenID), buyer);

        nft.approve(address(nftMarket), tokenID);
        nftMarket.listItem(address(nft), tokenID, price);

        token.transfer(buyer, price + 100);
        
        vm.prank(buyer);
        token.approve(address(nftMarket), price);

        SigUtils_nftmarket.Nft_witheList memory permit = SigUtils_nftmarket.Nft_witheList({
            wallet: buyer
        });

        bytes32 digest = sigUtils_nftmarket.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(nftownerPrivateKey, digest);
        
        vm.prank(buyer);
        nftMarket.verifyBuy(buyer, v, r, s, address(nft), tokenID, price);

        assertEq(nft.ownerOf(tokenID), buyer);
    }
}