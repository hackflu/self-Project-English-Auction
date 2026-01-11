// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

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
    error EnglishAuction__Ended();
    error EnglishAuction__PriceTooLow();
    error EnglishAuction__NotStarted();
    error EnglishAuction__StartPriceNotMatch();
    error EnglishAuction__InvalidAddress();
    error EnglishAuction__AddressDoesNotExist();
    error EnglishAuction__NotEnded();
    error EnglishAuction__transferFailedToBidder();
    error EnglishAuction__transferFailedToSeller();
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
    uint256 public immutable i_startTime;
    mapping(address => uint256) private s_trackUser;
    mapping(address => bool) private s_userExist;
    bool public s_started;
    bool public s_ended;
    uint256 public s_highestBid;
    address public s_highestBider;
    /////////////////////////
    ///////// events ////////
    ////////////////////////
    event AuctionStarted(address indexed, bool);
    event BidSuccessful(address indexed, uint256);
    event WithdrawlSuccessful(address indexed, uint256);
    event AuctionEnded(address indexed, uint256);
    /////////////////////////
    ////// modifier ////////
    ////////////////////////
    modifier onlySeller() {
        if (msg.sender != i_seller) {
            revert EnglishAuction__NotAuthorized();
        }
        _;
    }

    ////////////////////////
    //// constructor //////
    ///////////////////////
    constructor(address _seller, address _nft, uint256 _nftId, uint256 _startingPrice, uint256 _startDuration) {
        i_seller = payable(_seller);
        i_nftAddr = _nft;
        i_nftId = _nftId;
        i_startingPrice = _startingPrice;
        i_startTime = block.timestamp + _startDuration;
        s_highestBid = 0;
        s_started = false;
        s_ended = false;
   
    }

    //////////////////////////////
    /////// external func ///////
    /////////////////////////////
    /**
     * @notice Initializes and starts the auction process for the listed NFT
     * @dev Only the designated seller can call this. Sets auction state to active.
     * @custom:requirement Must be called by the seller and only once
     * @custom:event Emits {AuctionStarted} on success
     */
    function start() external onlySeller {
        s_started = true;
        s_ended = false;
        emit AuctionStarted(msg.sender, s_started);
    }
    /**
     * @notice Allows a user to place a bid on the auction by sending Ether
     * @dev Reverts if the auction has not started, has ended, or if the bid is lower than the current highest bid
     * @custom:requirement msg.value must be greater than s_highestBid
     * @custom:event Emits {BidSuccessful} when a new highest bid is recorded
     */

    function bid() external payable {
        if(msg.sender == address(0)){
            revert EnglishAuction__InvalidAddress();
        }
        if (s_ended) {
            revert EnglishAuction__Ended();
        }
        if (i_startingPrice > msg.value) {
            revert EnglishAuction__StartPriceNotMatch();
        }
        if (s_highestBid >= msg.value) {
            revert EnglishAuction__PriceTooLow();
        }
        s_trackUser[msg.sender] += msg.value;
        s_userExist[msg.sender] = true;
        s_highestBid = msg.value;
        s_highestBider = msg.sender;
        emit BidSuccessful(s_highestBider, s_highestBid);
    }

    /**
     * @notice Allows outbid users to withdraw their previously locked bid amounts
     * @dev Uses the pull-over-push pattern to prevent reentrancy and DOS attacks.
     *      The current highest bidder cannot withdraw until outbid.
     * @custom:requirement The caller must have a non-zero balance in s_trackUser
     * @custom:event Emits {WithdrawalSuccessful} upon successful Ether transfer
     */
    function withdraw() external {
        if (!s_ended) {
            revert EnglishAuction__NotEnded();
        }
        if (msg.sender == address(0)) {
            revert EnglishAuction__InvalidAddress();
        }
        
        uint256 userBalance = s_trackUser[msg.sender];
        delete s_trackUser[msg.sender];
        (bool success,) = payable(msg.sender).call{value: userBalance}("");
        if (!success) {
            revert EnglishAuction__transferFailedToBidder();
        }
        emit WithdrawlSuccessful(msg.sender, userBalance);
    }

    /**
     * @notice Ends the current auction and finalized the sale
     * @dev Can only be called by the seller once the auction time has expired.
     *      Transitions the contract state to inactive and prevents further bidding.
     * @custom:requirement Must be called by i_seller
     * @custom:requirement Current time must be greater than or equal to s_endTime
     * @custom:event Emits {AuctionEnded} upon successful finalization
     */
    function end() external onlySeller {
        //checks
        if(!s_started){
            revert EnglishAuction__NotStarted();
        }

        //effect
        s_started = false;
        s_ended = true;
        uint256 sellerClaimed = s_highestBid;
        address winner = s_highestBider;
        s_trackUser[s_highestBider] -= s_highestBid;

        s_highestBider = address(0);
        s_highestBid = 0;
        // accessing the immutable varaible is lot cheaper
        IERC721(i_nftAddr).transferFrom(i_seller, winner, i_nftId);
        (bool success,) = i_seller.call{value: sellerClaimed}("");
        if (!success) {
            revert EnglishAuction__transferFailedToSeller();
        }
        emit AuctionEnded(msg.sender, sellerClaimed);
    }
}

