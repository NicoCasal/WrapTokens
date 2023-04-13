//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "contracts/wrapERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lotery is WRTW, Ownable {
    WRTW public remake;

    constructor(WRTW _remake) {
        remake = _remake;
    }

    //winners
    address public winner;

    mapping(address => uint256) public lotery_Tickets;

    //token price
    function TokenPriece(uint256 _numTokens) internal pure returns (uint256) {
        return _numTokens * (1 ether);
    }

    //user Token Balance
    function tokenBalance(address _account) public view returns (uint256) {
        return balanceOf(_account);
    }

    // smart contract token valance wiew
    function tokenBalanceSc() public view returns (uint256) {
        return balanceOf(address(this));
    }

    //ERC20 Token generator (only owner)
    function minting(uint256 _amount) public onlyOwner {
        mint(address(this), _amount);
    }

    function buyTokens() public {
        remake.deposit();
        lotery_Tickets[msg.sender] = block.timestamp;
    }

    // random winner
    function selectWinner() public onlyOwner {
        // generate a random winner
        uint256 numberOfBuyers = address(this).balance;
        require(numberOfBuyers > 0, "no buyers");
        uint256 indexWinner = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, numberOfBuyers)
            )
        ) % numberOfBuyers;

        // winner address obtained
        address winnerAddress;
        uint256 count = 0;
        for (uint256 i = 0; i <= 2 ** 160; i++) {
            address possibleWinner = address(
                uint160(bytes20(keccak256(abi.encodePacked(i))))
            );
            if (lotery_Tickets[possibleWinner] != 0) {
                if (count == indexWinner) {
                    winnerAddress = possibleWinner;
                    break;
                } else {
                    count++;
                }
            }
        }

        // tranfer to winner
        payable(winnerAddress).transfer((address(this).balance * 80) / 100);
        payable(owner()).transfer((address(this).balance * 20) / 100);
    }
}
