// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyCollectible is ERC721 , Ownable {
    constructor(address _to) ERC721("MyCollectible", "MCO") Ownable(msg.sender) {
        _mint(_to, 1);
    }

    function transferFromOwner(address _from ,address _to , uint256 _tokenId) public onlyOwner {
        _transfer(_from , _to , _tokenId);
    }

}