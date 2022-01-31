// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.3.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.3.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@4.3.2/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts@4.3.2/access/AccessControl.sol";
import "@openzeppelin/contracts@4.3.2/access/Ownable.sol";
import "@openzeppelin/contracts@4.3.2/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts@4.3.2/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts@4.3.2/token/ERC20/extensions/ERC20FlashMint.sol";

contract STIMA is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, Ownable, ERC20Permit, ERC20Votes, ERC20FlashMint {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    uint256 private _numenator;
    uint256 private _denomenator;
    uint256 private _totalHolded;
    
    mapping(address => uint256) private _holdes; // mapping for hold amount of minted tokens before the item arrives at the warehouse. when tokens are in the hold then owner cant transfer them and admins can burn them or approve when the item has arrives

    constructor() ERC20("STIMA", "STM") ERC20Permit("STIMA") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SNAPSHOT_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _numenator = 10;
        _denomenator = 100;
        _totalHolded = 0;
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 ownerAmount = (amount / _denomenator) * _numenator;
        uint256 toAmount = amount - ownerAmount;
        _mint(to, toAmount);
        _holdes[to] += toAmount; // hold minted amount
        _totalHolded += toAmount; // 
        _mint(owner(), ownerAmount);
    }

    // The following functions are overrides required by Solidity.
    // check that account have necessary balance not into hold

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
        if (from != address(0) && (to != address(0) || from == msg.sender)) {
            uint256 senderRealBalance = balanceOf(from) - _holdes[from];
            require(senderRealBalance >= amount, "ERC20: not enough tokens not in hold");
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    
    // display amount in hold of specific account
    function holdOf(address account) public view virtual returns (uint256) {
        return _holdes[account];
    }
    
    function releaseBalance(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _holdes[account] -= amount;
        _totalHolded -= amount;
    }
    
    function burnFromHold(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(account != address(0), "ERC20: burn from the zero address");

        require(amount <= _holdes[account], "ERC20: burn more than holded");
        _burn(account, amount);
        _holdes[account] -= amount;
        _totalHolded -= amount;
        
    }
    
    function setMinterPart(uint256 numerator,uint256 denominator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(numerator < denominator, "ERC20: part of minter must be less than amount");
        _numenator = numerator;
        _denomenator = denominator;
    }
    
    function getNumenator() public view returns (uint256) {
        return _numenator;
    }
    
    function getDenominator() public view returns (uint256) {
        return _denomenator;
    }
    
    function getTotalHolded() public view returns (uint256) {
        return _totalHolded;
    }
    
}
