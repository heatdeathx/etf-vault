// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC20 } from "./interfaces/IERC20.sol";
import { SafeTransfer } from "./libraries/SafeTransfer.sol";
import { ERC20 } from "./ERC20.sol";

/// @title Fusion
/// @notice An exchange traded fund with fixed paramters on deployment.
/// @dev Implements ERC-4626.
contract Fusion is ERC20 {
    using SafeTransfer for address;

    event Deposit(address indexed caller, address indexed to, uint256[] assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed to, address indexed owner, uint256[] assets, uint256 shares);

    struct Token {
        address token;
        uint96 ratio;
    }

    uint256 constant public max = 1e5; // 100%
    uint256 constant public min = 1; // 0.01%

    Token[] public tokens;
    uint256 public immutable length;

    constructor(string memory name_, string memory symbol_, Token[] memory tokens_)
        ERC20(name_, symbol_, 18)
    {
        length = tokens_.length;

        uint256 net;
        for (uint256 i = 0; i < length; i++) {
            require(tokens_[i].ratio >= min);
            net += tokens_[i].ratio;

            tokens[i] = tokens_[i];
        }
        require(net == max);
    }

    function totalAssets() external view returns (uint256[] memory assets) {
        for (uint256 i = 0; i < length; i++) {
            assets[i] = IERC20(tokens[i].token).balanceOf(address(this));
        }
    }

    function convertToAssets(uint256 shares) public view returns (uint256[] memory assets) {
        for (uint256 i = 0; i < length; i++) {
            assets[i] = shares * tokens[i].ratio / max;
        }
    }

    function maxMint(address owner) public view virtual returns (uint256) {
        return type(uint256).max - balanceOf[owner];
    }

    function previewMint(uint256 shares) public view returns (uint256[] memory assets) {
        assets = convertToAssets(shares);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    function previewRedeem(uint256 shares) public view returns (uint256[] memory assets) {
        assets = convertToAssets(shares);
    }

    function mint(uint256 shares, address to) external returns (uint256[] memory assets) {
        require(shares > 0);

        assets = previewMint(shares);

        for (uint256 i = 0; i < length; i++) {
            require(assets[i] > 0);
            tokens[i].token.safeTransferFrom(msg.sender, address(this), assets[i]);
        }

        _mint(to, shares);
        emit Deposit(msg.sender, to, assets, shares);
    }

    function redeem(uint256 shares, address to, address owner) external returns (uint256[] memory assets) {
        require(shares > 0);

        _spend(msg.sender, shares);
        _burn(owner, shares);

        assets = previewRedeem(shares);

        for (uint256 i = 0; i < length; i++) {
            require(assets[i] > 0);
            tokens[i].token.safeTransfer(to, assets[i]);
        }

        emit Withdraw(msg.sender, to, owner, assets, shares);
    }
}
