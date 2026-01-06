// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importăm contractul MyToken și biblioteca Ownable de la OpenZeppelin
import "./MyToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Importăm și definițiile celorlalte contracte pentru a permite interacțiunea
import "./SponsorFunding.sol";
import "./DistributeFunding.sol";

contract CrowdFunding is Ownable {
    enum State { Nefinantat, Prefinantat, Finantat }
    State public state = State.Nefinantat;
    
    MyToken public token;
    uint256 public fundingGoal;
    uint256 public totalCollected;
    mapping(address => uint256) public contributions;

    // Constructorul primește adresa token-ului și ținta de finanțare
    constructor(address _tokenAddress, uint256 _goal) Ownable(msg.sender) {
        token = MyToken(_tokenAddress);
        fundingGoal = _goal * 10**18;
    }

    function getStateString() public view returns (string memory) {
        if (state == State.Nefinantat) return "nefinantat";
        if (state == State.Prefinantat) return "prefinantat";
        return "finantat";
    }

    function deposit(uint256 amount) external {
        require(state == State.Nefinantat, "Colectarea este inchisa");
        uint256 amountInDecimals = amount * 10**18;
        
        // Transferă tokeni de la utilizator la acest contract
        token.transferFrom(msg.sender, address(this), amountInDecimals);
        contributions[msg.sender] += amountInDecimals;
        totalCollected += amountInDecimals;

        if (totalCollected >= fundingGoal) {
            state = State.Prefinantat;
        }
    }

    function withdraw(uint256 amount) external {
        require(state == State.Nefinantat, "Nu se mai pot retrage fonduri");
        uint256 amountInDecimals = amount * 10**18;
        require(contributions[msg.sender] >= amountInDecimals, "Suma prea mare");

        contributions[msg.sender] -= amountInDecimals;
        totalCollected -= amountInDecimals;
        token.transfer(msg.sender, amountInDecimals);
    }

    function requestSponsorship(address sponsorFundingAddr) external onlyOwner {
        require(state == State.Prefinantat, "Trebuie sa fie prefinantat");
        SponsorFunding sponsor = SponsorFunding(sponsorFundingAddr);
        sponsor.provideSponsorship();
        state = State.Finantat;
    }

    function transferToDistribution(address distributeFundingAddr) external onlyOwner {
        require(state == State.Finantat, "Trebuie sa fie finantat (cu sponsorizare)");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(distributeFundingAddr, balance);
        DistributeFunding(distributeFundingAddr).receiveFunds(balance);
    }
}