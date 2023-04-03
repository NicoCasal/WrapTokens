//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/ERC20.sol";
import "contracts/wrapERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lotery is ERC20, Ownable {
    constructor() ERC20("TOKEN", "TK") {
        mint(address(this), 1000);
    }

    //winners
    address public winner;
    //Register
    mapping(address => address) public user_contract;

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

    //smart contract ethers balance view
    function blanceEthersSC() public view returns (uint256) {
        return address(this).balance / 10 ** 18;
    }

    //ERC20 Token generator (only owner)
    function minting(uint256 _amount) public onlyOwner {
        mint(address(this), _amount);
        emit Deposito();
    }
}
