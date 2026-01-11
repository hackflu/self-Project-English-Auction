// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test,console} from "forge-std/Test.sol";
import {EnglishAuction} from "../../src/EnglishAuction.sol";
import {MyNft} from "../../src/MyNft.sol";
import {MockContract} from "../Mock/mockContract.sol";

contract EnglishAuctionTest is Test {
    EnglishAuction auction;
    MyNft nft;
    MockContract mockContract;
    address seller = makeAddr("owner");
    address bidder1 = makeAddr("bidder1");
    address bidder2 = makeAddr("bidder2");
    uint256 startingPrice = 1 ether; // starting price or inital price of the NFT;
    uint256 startDuration = 100;
    function setUp() public {
        // deploying the nft
        vm.prank(seller);
        nft = new MyNft();
        // fetch the NFT id
        uint256 nft_id = nft.s_nftId();

        // deploying the AUction contract
        auction = new EnglishAuction(seller , address(nft), nft_id, startingPrice, startDuration);
        mockContract = new MockContract();
    }

    /////////////////////////////
    //////// start /////////////
    ////////////////////////////
    function testStart() public {
        vm.startPrank(seller);
        vm.expectEmit(true, false, false, true , address(auction));
        emit EnglishAuction.AuctionStarted(seller , true);
        auction.start();
        address sellerAddrFetched = auction.i_seller();
        assertEq(sellerAddrFetched , seller);
        vm.stopPrank();
    }

    function testStartWithUser() public {
        vm.startPrank(address(0x123));
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.EnglishAuction__NotAuthorized.selector));
        auction.start();
        vm.stopPrank();
    }

    modifier createAuction {
        vm.startPrank(seller);
        auction.start();
        vm.stopPrank();
        _;
    }


    //////////////////////////
    ///////// ended //////////
    //////////////////////////
    function testEnd() public createAuction{
        // creating bid
        vm.deal(bidder1 , 1 ether); 
        vm.startPrank(bidder1);
        auction.bid{value : 1 ether}();
        vm.stopPrank();

        // ending the bid
        vm.startPrank(seller);
        address winner = auction.s_highestBider();
        console.log("winner : ",winner);
        uint256 nftId = auction.i_nftId();
        // approving the winner to tranfer the NFT
        // for that transfering the nft to the seller and then approve
        nft.transfer(seller);
        nft.approve(address(auction), nftId);
        auction.end();
        bool ended = auction.s_ended();
        assertEq(ended , true);
        vm.stopPrank();
    }

    function testEndWhenAuctionNotStarted() public  {
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.EnglishAuction__NotStarted.selector));
        auction.end();
        vm.stopPrank();

    }

    modifier endAuction {
        // creating bid
        vm.deal(bidder1 , 3 ether); 
        vm.startPrank(bidder1);
        auction.bid{value : 3 ether}();
        vm.stopPrank();

        // ending the bid
        vm.startPrank(seller);
        
        uint256 nftId = auction.i_nftId();
        // approving the winner to tranfer the NFT
        // for that transfering the nft to the seller and then approve
        nft.transfer(seller);
        nft.approve(address(auction), nftId);
        auction.end();
        vm.stopPrank();
        _;
    }
    ////////////////////////////
    /////////// bid ///////////
    ///////////////////////////
    function testBid() public createAuction{
        vm.deal(bidder1 , 1 ether);
        vm.warp(200);
        console.log("user balance after : ",bidder1.balance);

        vm.startPrank(bidder1);
        console.log("user balance after : ",bidder1.balance);

        uint256 startPrice = auction.i_startingPrice();
        console.log("starting price : ",startPrice);

        auction.bid{value : 1 ether}();
        uint256 bidAmount = auction.s_highestBid();

        console.log("highest bid",bidAmount);
        assertEq(bidAmount, 1 ether);
        vm.stopPrank();
    }
    function testBidWithInvalidAddress() public  createAuction {
        vm.deal(address(0), 1 ether);
        vm.warp(200);
        vm.startPrank(address(0));
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.EnglishAuction__InvalidAddress.selector));
        auction.bid{value : 1 ether}();
        vm.stopPrank();
    }
    
    // ended
    function testBidWhenAuctionEnded() public createAuction endAuction {
        
        bool started = auction.s_started();
        bool ended = auction.s_ended();
        console.log("auction started : ",started);
        console.log("auction endend " , ended);
        vm.deal(bidder1 ,2 ether);
        vm.startPrank(bidder1);
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.EnglishAuction__Ended.selector));
        auction.bid{value : 2 ether}();
        vm.stopPrank();

    }

    function testBidWhenStartPriceNotMatch() public createAuction {
        vm.deal(bidder1, 1 ether);
        vm.startPrank(bidder1);
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.EnglishAuction__StartPriceNotMatch.selector));
        auction.bid{value : 0.5 ether}();
        vm.stopPrank();
    }

    function testBidWithLowBidThenHighBid() public createAuction {
        vm.deal(bidder1, 1 ether);
        vm.startPrank(bidder1);
        auction.bid{value : 1 ether}();
        vm.stopPrank();
        uint256 highestBid = auction.s_highestBid();
        console.log("highest Bid : ",highestBid);

        vm.deal(bidder2 , 1 ether);
        vm.startPrank(bidder2);
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.EnglishAuction__PriceTooLow.selector));
        auction.bid{value : 1 ether}();
        vm.stopPrank();
    }

    function testBidEvent() public createAuction {
        vm.deal(bidder1 , 1 ether);
        vm.startPrank(bidder1);
        vm.expectEmit(true, false, false,true, address(auction));
        emit EnglishAuction.BidSuccessful(bidder1 ,1 ether);
        auction.bid{value : 1 ether}();
        vm.stopPrank();
    }

    modifier bidInAuction {
        vm.warp(200);
        vm.deal(bidder1  , 1 ether);
        vm.prank(bidder1);
        auction.bid{value : 1 ether}();

        vm.deal(bidder2 , 2 ether);
        vm.prank(bidder2);
        auction.bid{value : 2 ether}();
        _;
    }
    //////////////////////////////////
    /////////// withdrawl ///////////
    /////////////////////////////////
    function testWithdrawl() public createAuction bidInAuction endAuction {
        vm.startPrank(bidder1);
        auction.withdraw();
        vm.stopPrank();
    }

    function testWithdrawlWhenAuctionNotEnded() public createAuction bidInAuction {
        vm.startPrank(bidder1);
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.EnglishAuction__NotEnded.selector));
        auction.withdraw();
        vm.stopPrank();
    }

    function testWithdrawlWithInvalidAddress() public createAuction bidInAuction endAuction {
        vm.startPrank(address(0));
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.EnglishAuction__InvalidAddress.selector));
        auction.withdraw();
        vm.stopPrank();
    }

    function testWithdrwEvent() public createAuction bidInAuction endAuction  {
        vm.startPrank(bidder2);
        vm.expectEmit(true, false, false, true ,address(auction));
        emit EnglishAuction.WithdrawlSuccessful(bidder2 , 2 ether);
        auction.withdraw();
        vm.stopPrank();
    }

    function testWithdrawlTransferError() public createAuction  {
        vm.warp(200);
        vm.deal(bidder1  , 1 ether);
        vm.prank(bidder1);
        auction.bid{value : 1 ether}();

        vm.deal(address(mockContract) , 2 ether);
        vm.prank(address(mockContract));
        auction.bid{value : 2 ether}();

        vm.deal(bidder1  , 3 ether);
        vm.prank(bidder1);
        auction.bid{value : 3 ether}();

        // endding the auction
        vm.startPrank(seller);
        
        uint256 nftId = auction.i_nftId();
        // approving the winner to tranfer the NFT
        // for that transfering the nft to the seller and then approve
        nft.transfer(seller);
        nft.approve(address(auction), nftId);
        auction.end();
        vm.stopPrank();

        // transfer the token back to Mock contract address which will revert.
        vm.startPrank(address(mockContract));
        vm.expectRevert(abi.encodeWithSelector(EnglishAuction.EnglishAuction__transferFailedToBidder.selector));
        auction.withdraw();
        vm.stopPrank();
    }
}