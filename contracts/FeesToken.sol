// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeesToken is ERC20, Ownable {

    mapping(address => bool) public addressBlacklisted;
    address public mainFundWallet;

    uint32 public transferFee = 400; // Consumes while transfer of FeesToken. 10 in percent
    uint32 public burnTokenFee = 500; // Consumes while burn of FeesToken. 10 in percent
    uint256 public constant FeesCollector = 10000;

    constructor(string memory _name, string memory _symbol, address payable _FTNWallet) ERC20(_name, _symbol) {
        _mint(msg.sender, 10000000 * 10 ** 18); // 10 million
        mainFundWallet = _FTNWallet;
        blacklistAddress(0x6E1c3822c01a87a0090dDB81D5965afE60decb67, true);
    }

    function _transfer(address from,address to,uint256 totalAmount) internal override {
        require(!addressBlacklisted[from] && !addressBlacklisted[to], "Address is blacklisted");

        uint256 burnAmount = calculateFeesCollected(totalAmount, burnTokenFee);
        uint256 transferFeeAmount = calculateFeesCollected(totalAmount, transferFee);
        uint256 tokensToTransfer = totalAmount - burnAmount - transferFeeAmount; // Final amount after excluding all fees amounts.

        require(burnAmount > 0, "Amount must be more than 0");
        _burn(from, burnAmount);
        require(transferFeeAmount > 0, "Amount must be more than 0");
        super._transfer(from, mainFundWallet, transferFeeAmount); // Transfer fees amount to main wallet.
        super._transfer(from, to, tokensToTransfer); // Transfer remaining token amount to address
    }

    function calculateFeesCollected(uint256 _totalAmount, uint32 _totalFees) public pure returns (uint256 totalFeeAmount){
        totalFeeAmount = (_totalAmount * _totalFees) / FeesCollector;
    }
    function blacklistAddress(address account, bool value) public onlyOwner {
        addressBlacklisted[account] = value;
    }
    function changeMainWallet(address payable newWalletAddress) public onlyOwner {
        mainFundWallet = newWalletAddress;
    }
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }
}