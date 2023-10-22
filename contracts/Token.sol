// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GALLToken is ERC1155 {
    using SafeERC20 for IERC20;

    uint8 public constant maxCnt = 200;

    bool public extraMintAllowed;

    uint256 public tokenId;

    uint256 public price;

    address public owner;

    address public priceToken;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        string memory uri_,
        address _priceToken,
        uint256 _price
    ) ERC1155(uri_) {
        require(_priceToken != address(0), "invalid price token");
        require(_price > 0, "invalid price");
        priceToken = _priceToken;
        price = _price;
        extraMintAllowed = false;
        owner = msg.sender;
    }

    /// @notice Set extran information when maxCnt of NFT is sold out.
    ///         Without setting extra information, users can't mint NFT anymore.
    /// @dev Only owner can call this function.
    /// @param _price New price for minting NFT.
    function setExtraInfo(uint256 _price) external onlyOwner {
        require(_price > 0, "invalid price");
        price = _price;
        extraMintAllowed = true;
    }

    function mint(uint8 _amount) external {
        address sender = msg.sender;
        uint256 requirePrice = price * _amount;
        require(
            tokenId + _amount < maxCnt || extraMintAllowed,
            "cannot mint more"
        );
        require(sender != address(0), "invalid sender address");
        require(
            IERC20(priceToken).balanceOf(sender) >= requirePrice,
            "not enough balance to mint"
        );

        tokenId += _amount;
        IERC20(priceToken).safeTransferFrom(
            sender,
            address(this),
            requirePrice
        );
        _mint(sender, tokenId, _amount, "");
    }

    function withdraw() external onlyOwner {
        uint256 balance = IERC20(priceToken).balanceOf(address(this));
        if (balance == 0) return;
        IERC20(priceToken).safeTransfer(owner, balance);
    }
}
