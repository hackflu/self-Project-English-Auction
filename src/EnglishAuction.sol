// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * @title English Auction Contract
 * @author devilknowyou
 * @dev A simple Contract. main focused towards the test and scripting.
*/

contract EnglishAuction {
    ///////////////////////
    ////// error /////////
    /////////////////////
    error EnglishAuction__NotAuthorized();
    error EnglishAuction__AuctionEnded();
    error EnglishAuction__PriceTooLow();
    error EnglishAuction__AuctionNotStarted();
    error EnglisAuction__StartingPriceNotMatch();

    //////////////////////////////
    ///// type decleration //////
    /////////////////////////////

    ////////////////////////////
    ///// state variable //////
    ///////////////////////////
    address payable public immutable i_seller;
    address public immutable i_nftAddr;
    uint256 public immutable i_nftId;
    uint256 public immutable i_startingPrice;
    mapping(address => uint256) public s_trackUser;
    bool private s_started;
    uint256 private s_endTime;
    uint256 private s_highestBid;

    /////////////////////////
    ///////// events ////////
    ////////////////////////
    event AuctionStarted(address indexed, bool , uint256);
    event BidSuccessful(address indexed , uint256);

    /////////////////////////
    ////// modifier ////////
    ////////////////////////
    modifier onlyOwner {
        if(msg.sender != i_seller){
            revert EnglishAuction__NotAuthorized();
        }
        _;
    }
    ////////////////////////
    //// constructor //////
    ///////////////////////
    constructor(address _seller , address _nft , uint256 _nftId ,uint56 _startingPrice) {
        i_nftAddr = _nft;
        i_nftId = _nftId;
        i_startingPrice = _startingPrice;
        i_seller = _seller;
    }
    //////////////////////////////
    /////// external func ///////
    /////////////////////////////
    function start(uint256 _waitindDuration) external onlyOwner{
        s_started = true;
        s_endTime = i_started + _waitindDuration;
        emit AuctionStarted(msg.sender , s_started , s_endTime);
    }

    function bid() external payable {
        if(!s_started){
            revert EnglishAuction__AuctionNotStarted();
        }
        if(block.timestamp > i_endTime){
            revert EnglishAuction__AuctionEnded();
        }
        if(i_startingPrice > msg.value){
            revert EnglisAuction__StartingPriceNotMatch();
        }
        if(s_highestBid > msg.value ){
            revert EnglishAuction__PriceTooLow();
        }
        s_trackUser[msg.sender] += msg.value;
        s_highestBid = msg.value;
        emit BidSuccessful(msg.sender msg.value);
    }

    function withdraw() external {}

    function end() external {}
}
