// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MyToken.sol";
import "./CrowdFunding.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SponsorFunding is Ownable {
    MyToken public token;
    CrowdFunding public crowdFunding;
    uint256 public sponsorPercentage; // de ex. 20 pentru 20%

    constructor(address _tokenAddress, address _crowdAddress, uint256 _percent) Ownable(msg.sender) {
        token = MyToken(_tokenAddress);
        crowdFunding = CrowdFunding(_crowdAddress);
        sponsorPercentage = _percent;
    }

    // Funcția cerută: proprietarul cumpără tokens pentru sponsorizări de la contractul token
    function buySponsorTokens(uint256 amount) external payable onlyOwner {
        token.buyTokens{value: msg.value}(amount);
    }

    function provideSponsorship() external {
        // Doar contractul CrowdFunding are voie să declanșeze viramentul
        require(msg.sender == address(crowdFunding), "Doar CrowdFunding poate apela");
        
        uint256 collected = crowdFunding.totalCollected();
        uint256 sponsorAmount = (collected * sponsorPercentage) / 100;

        // Verifică dacă există balanță suficientă; dacă nu, nu virează nimic (anulare)
        if (token.balanceOf(address(this)) >= sponsorAmount) {
            token.transfer(address(crowdFunding), sponsorAmount);
        }
    }
}