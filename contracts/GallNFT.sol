// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GALLNFT is ERC1155 {
    using SafeERC20 for IERC20;

    uint8 public constant maxCnt = 200;

    uint8 public constant royaltyRate = 5;

    uint256 public tokenId;

    uint256 public airdropAmount;

    uint256 public price;

    address public owner;

    address public priceToken;

    address public royaltyWallet;

    // Address of the GALL token contract
    address public gallTokenAddress ; // Replace with the actual GALL token contract address

    // Address of the recipient
    address public recipient ; // Replace with the recipient's address

    mapping(uint256 => uint256) public mintedCounts;

    mapping(uint256 => bool) public extraMintAllowed;

    mapping(uint256 => uint256) public extraMintPrice;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        string memory uri_,
        address _priceToken,
        address _royaltyWallet,
        address _gallTokenAddress,
        uint256 _price,
        uint256 _airdropAmount
    ) ERC1155(uri_) {
        require(_priceToken != address(0), "invalid price token");
        require(_price > 0, "invalid price");
        require(_royaltyWallet != address(0), "invalid wallet address");
        require(_gallTokenAddress != address(0), "invalid token address");
        require(_airdropAmount > 0, "invalid airdrop amount");
        priceToken = _priceToken;
        gallTokenAddress = _gallTokenAddress;
        price = _price;
        airdropAmount = _airdropAmount;
        owner = msg.sender;
        royaltyWallet = _royaltyWallet;
    }

    /// @notice Set extran information when maxCnt of NFT is sold out.
    ///         Without setting extra information, users can't mint NFT anymore.
    /// @dev Only owner can call this function.
    /// @param _price New price for minting NFT.
    function setExtraInfo(uint256 _tokenId, uint256 _price) external onlyOwner {
        require(_price > 0, "invalid price");

        extraMintPrice[_tokenId] = _price;
        extraMintAllowed[_tokenId] = true;
    }

    function mint(uint256 _tokenId, uint8 _amount) external {
        address sender = msg.sender;
        uint256 requirePrice = price * _amount;
        require (_amount > 0, "invalid mint amount");
        require(
            mintedCounts[_tokenId] + _amount < maxCnt || extraMintAllowed[_tokenId],
            "cannot mint more"
        );
        require(sender != address(0), "invalid sender address");
        requirePrice = mintedCounts[_tokenId] + _amount < maxCnt ? requirePrice : extraMintPrice[_tokenId] * _amount;
        require(
            IERC20(priceToken).balanceOf(sender) >= requirePrice,
            "not enough balance to mint"
        );

        uint256 royaltyAmount = requirePrice * uint256(royaltyRate) / 100;
        uint256 transferAmount = requirePrice - royaltyAmount;
        mintedCounts[_tokenId] += _amount;

        if (royaltyAmount > 0) {
            IERC20(priceToken).safeTransferFrom(sender, royaltyWallet, royaltyAmount);
        }
        IERC20(priceToken).safeTransferFrom(
            sender,
            address(this),
            transferAmount
        );
        _mint(sender, tokenId ++, _amount, "");

        uint256 requireAirdropAmount = airdropAmount * _amount;
        require(
            IERC20(gallTokenAddress).balanceOf(address(this)) >= requireAirdropAmount, 
            "Insufficient balance"
        );

        IERC20(gallTokenAddress).safeTransfer(sender, requireAirdropAmount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = IERC20(priceToken).balanceOf(address(this));
        if (balance == 0) return;
        IERC20(priceToken).safeTransfer(owner, balance);
    }
}
