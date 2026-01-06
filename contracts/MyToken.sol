// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    uint256 public tokenPrice; // Preț în wei per token

    constructor(uint256 initialSupply, uint256 _price) ERC20("ProjectToken", "PTK") Ownable(msg.sender) {
        tokenPrice = _price;
        _mint(address(this), initialSupply * 10**decimals());
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }

    function buyTokens(uint256 amount) external payable {
        uint256 cost = amount * tokenPrice;
        require(msg.value >= cost, "Fonduri insuficiente pentru cumparare");
        _transfer(address(this), msg.sender, amount * 10**decimals());
        
        // Restituire rest dacă este cazul
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}