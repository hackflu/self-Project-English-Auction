// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";

import {EnglishAuction} from "../src/EnglishAuction.sol";
import {MyNft} from "../src/MyNft.sol";

contract DeployScript is Script{
    MyNft nft;
    EnglishAuction auction;
    
    function run(address _seller, uint256 _startingPrice, uint256 _startDuration) public returns(MyNft , EnglishAuction){
        vm.startBroadcast();
        // Deploye the nft
        nft = new MyNft();

        // fetching the NFT id
        uint256 id = nft.s_nftId();

        // Deploying the Auction contract
        auction = new EnglishAuction(_seller , address(nft), id,_startingPrice, _startDuration);
        vm.stopBroadcast();
        return (nft , auction);
    }
}