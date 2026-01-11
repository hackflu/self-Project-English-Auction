// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyNft is ERC721, Ownable {
    uint256 public s_nftId = 1;
    constructor() ERC721("MyCollectible", "MCO") Ownable(msg.sender) {
        _mint(msg.sender, s_nftId);
    }

    function transfer(address _to) external onlyOwner {
        _transfer(owner(), _to, s_nftId);
    }
}
