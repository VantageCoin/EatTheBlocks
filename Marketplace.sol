// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Homework.sol";
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

    function addTokenToAuction(string memory _symbol, uint _deadline, uint tokenid, uint _price, address _tokenContractAddress) external {
         // Verify if the token contract address is ERC721 compliant
        ERC721Interface tokenContract = ERC721Interface(_tokenContractAddress);
        require(tokenContract.ownerOf(1) != address(0), "Not ERC721");

          // Transfer the token to the buyer
        tokenContract.transferFrom(t.seller, address(this), t.tokenid);

        
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

        ERC721Interface tokenContract = ERC721Interface(_tokenContractAddress);

          // Transfer the token to the buyer
        tokenContract.transferFrom(address(this), b.buyer, t.tokenid);

        
        //Send Seller $$
        t.seller.call{value: sellershare}("");
        


        //send Owner $$
        owner.call{value: ownershare}("");     

        emit TokenSold(_symbol,t.seller, b.buyer);
    }

     
      function proof() external pure override returns (bytes32) {
        return keccak256("I have done this homework myself");
    }

}