//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "contracts/wrapERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lotery is WRTW, Ownable {
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
    }

    //user reggist
    function reggist() internal {
        address user = address(msg.sender);
        user_contract[msg.sender] = user;
    }

    //user info
    function userInfo(address _account) public view returns (address) {
        return user_contract[_account];
    }

    //TICKETS OBTAINED

    function buyTokens(uint256 _numTokens) public payable {
        if (user_contract[msg.sender] == address(0)) {
            reggist();
        }
        //priece
        uint256 priece = TokenPriece(_numTokens);
        require(msg.value >= priece, "inuficient founds to buy");
        //abaible tokens
        uint256 tokenBalance = tokenBalanceSc();
        require(_numTokens <= tokenBalance, "insuficient token founds to buy");
        //devoluvion restante
        uint256 returnValue = msg.value - priece;
        payable(msg.sender).transfer(returnValue);
        //send tokens user
        deposit();
    }
}
