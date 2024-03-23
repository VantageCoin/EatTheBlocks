// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Homework} from "./Homework.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ERC721Interface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Marketplace is Homework {

    event TokenAdded(string symbol, address seller, uint256 deadline);
    event TokenSold(string symbol, address seller, address buyer);

    error AuctionEnded();
    error AuctionHasNotEnded();
    error BidTooLow();

    address public owner;

    // bid + token one struct

    struct Token {
        string symbol;
        uint deadline;
        uint minprice;
        address seller;
        uint tokenid;
    }

    struct Bid {
        string symbol;
        uint bidprice;
        address buyer;
    }

    mapping(string => Token) public tokensForSale;

    mapping(string => Bid) public bids;

    constructor() {
        owner = msg.sender;
    }

    //add token to auction
    // address + tokenid hash instead of symbol

    function addTokenToAuction(string memory _symbol, uint _deadline, uint tokenid, uint _price, address _tokenContractAddress) external {
         // Verify if the token contract address is ERC721 compliant
        ERC721Interface tokenContract = ERC721Interface(_tokenContractAddress);
        require(tokenContract.ownerOf(tokenid) == msg.sender, "Seller does not own token");
        // check that sender owns the token & is an erc721 token

        tokenContract.transferFrom(msg.sender, address(this), tokenid);
        
        Token memory t = Token(_symbol, _deadline, _price, msg.sender, tokenid);
        tokensForSale[_symbol] = t;
        emit TokenAdded(_symbol, msg.sender, _deadline);
    }

    //get price of a token
    function getTokenPrice(string memory _symbol) external view returns (uint) {
        Token memory t = tokensForSale[_symbol];
        if (block.timestamp >= t.deadline) revert AuctionEnded();

        Bid storage b = bids[_symbol];

        if (b.bidprice > t.minprice) {
            return b.bidprice;
        }
        
        return t.minprice;
    }


    //make bid on a token
    function makeBid(string memory _symbol) external payable {

        Token memory t = tokensForSale[_symbol];
        if (block.timestamp >= t.deadline) revert AuctionEnded();


        Bid storage b = bids[_symbol];

        // no existing bid, add the bid
        if ( (b.bidprice == 0 && msg.value >= t.minprice) || (b.bidprice > 0 && msg.value > b.bidprice)) {
            Bid memory bid  = Bid (_symbol, msg.value, msg.sender);
            bids[_symbol] = bid;
        } else {
            revert BidTooLow();
        }
    }


    //end auction
    function endAuction(string memory _symbol) external {
        Token memory t = tokensForSale[_symbol];
        t.deadline = block.timestamp -1;
        tokensForSale[_symbol] = t;
    }

    //transfer token to new owner
    
    function transferToken(string memory _symbol) public {
         Token memory t = tokensForSale[_symbol];
        if (block.timestamp < t.deadline) revert AuctionHasNotEnded();

        Bid storage b = bids[_symbol];
        uint ownershare = b.bidprice / 100;
        uint sellershare = b.bidprice - ownershare;

        // seller can send nft to another address
        // transfer from seller to contract at start to prevent seller from re-selling nft

        // Transfer the token to the buyer
        ERC721Interface tokenContract = ERC721Interface(b.buyer);
        tokenContract.transferFrom(address(this), b.buyer, t.tokenid);

        //Send Seller $$
       (bool success1, ) = t.seller.call{value: sellershare}("");
       require(success1,"Seller share failed");
        //check if succeeded


        //send Owner $$
        (bool success2, ) = owner.call{value: ownershare}("");   
        require(success2, "Ownwer share failed");
        //  

        emit TokenSold(_symbol,t.seller, b.buyer);
    }

}
