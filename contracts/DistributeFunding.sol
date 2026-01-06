// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MyToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DistributeFunding is Ownable {
    MyToken public token;
    
    struct Shareholder {
        uint256 weight; // Ponderea beneficiarului (ex: 25 pentru 25%)
        bool withdrawn; // Indicator pentru a permite retragerea o singura data
    }
    
    mapping(address => Shareholder) public shareholders;
    uint256 public totalFundsReceived;
    bool public fundsReady = false;

    constructor(address _tokenAddress) Ownable(msg.sender) {
        token = MyToken(_tokenAddress);
    }

    /**
     * @dev Adaugă un beneficiar cu o anumită pondere.
     * Poate fi apelat doar de owner înainte ca fondurile să fie virate.
     */
    function addShareholder(address _addr, uint256 _weight) external onlyOwner {
        require(!fundsReady, "Distribuirea a inceput deja");
        require(_weight > 0 && _weight <= 100, "Pondere invalida");
        shareholders[_addr] = Shareholder(_weight, false);
    }

    /**
     * @dev Funcție apelată de CrowdFunding pentru a marca primirea tokenilor.
     */
    function receiveFunds(uint256 amount) external {
        // În mod ideal, aici se verifică dacă msg.sender este CrowdFunding
        totalFundsReceived += amount;
        fundsReady = true;
    }

    /**
     * @dev Permite fiecărui acționar să își retragă partea, o singură dată.
     */
    function claim() external {
        require(fundsReady, "Fondurile nu au fost inca virate");
        Shareholder storage s = shareholders[msg.sender];
        
        require(s.weight > 0, "Nu sunteti inregistrat ca beneficiar");
        require(!s.withdrawn, "Ati retras deja venitul");

        // Calculul venitului conform ponderii: (Total * Pondere) / 100
        uint256 shareAmount = (totalFundsReceived * s.weight) / 100;
        require(shareAmount > 0, "Suma de retras este zero");

        s.withdrawn = true;
        token.transfer(msg.sender, shareAmount);
    }
}