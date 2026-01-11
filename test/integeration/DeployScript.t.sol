// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployScript} from "../../script/DeployScript.s.sol";
import {EnglishAuction} from "../../src/EnglishAuction.sol";
import {MyNft} from "../../src/MyNft.sol";

contract DeployScriptTest is Test {
    DeployScript deploy;
    MyNft nft;
    EnglishAuction auction;
    address owner = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address seller = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 startPrice = 1 ether;
    uint256 startDuration = 1 hours;
    function setUp() public {
        deploy = new DeployScript();
    }

    function testDeployScript() public {
        (nft ,  auction) = deploy.run(seller , startPrice, startDuration);
        address sellerAddr = auction.i_seller();
        uint256 setStartPrice = auction.i_startingPrice();
        vm.stopPrank();
        assertEq(seller , sellerAddr);
        assertEq(startPrice , setStartPrice);
    }
}