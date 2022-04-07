// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC20 } from "./interfaces/IERC20.sol";
import { IERC20Metadata } from "./interfaces/IERC20Metadata.sol";
import { IERC2612 } from "./interfaces/IERC2612.sol";

/// @title ERC-20
/// @author OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/76fca3aec8e6ce2caf1c9c9a2c8396fe0882591a/contracts/token/ERC20/ERC20.sol)
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/e7deddffd5206cdec1d554c5361f529c2a525846/src/tokens/ERC20.sol)
/// @author Yield Protocol (https://github.com/yieldprotocol/yield-utils-v2/blob/ec57b07e53743f90a5ecd05daaad6c761c079729/contracts/token/ERC20.sol)
contract ERC20 is IERC20, IERC20Metadata, IERC2612 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @inheritdoc IERC20Metadata
    string public name;
    /// @inheritdoc IERC20Metadata
    string public symbol;
    /// @inheritdoc IERC20Metadata
    uint8 public decimals;
    /// @inheritdoc IERC20
    uint256 public totalSupply;
    /// @inheritdoc IERC20
    mapping(address => uint256) public balanceOf;
    /// @inheritdoc IERC20
    mapping(address => mapping(address => uint256)) public allowance;
    /// @inheritdoc IERC2612
    mapping(address => uint256) public nonces;

    /// @notice The `block.chainid` at deployment.
    uint256 internal immutable chainid;
    /// @notice The `DOMAIN_SEPARATOR` at deployment.
    bytes32 internal immutable domainseparator;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        chainid = block.chainid;
        domainseparator = _domainseparator();
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == chainid ? domainseparator : _domainseparator();
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 value) public virtual returns (bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        _spend(from, value);
        _transfer(from, to, value);

        return true;
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 value) public virtual returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /// @inheritdoc IERC2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        unchecked {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
            address signer = ecrecover(hash, v, r, s);
            require(signer != address(0) && signer == owner, "INVALID_SIGNER");
            allowance[signer][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    /* Internal */

    function _mint(address to, uint256 value) internal virtual {
        totalSupply += value;
        unchecked { balanceOf[to] += value; }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal virtual {
        balanceOf[from] -= value;
        unchecked { totalSupply -= value; }

        emit Transfer(from, address(0), value);
    }

    function _transfer(address from, address to, uint256 value) internal virtual {
        balanceOf[from] -= value;
        unchecked { balanceOf[to] += value; }

        emit Transfer(from, to, value);
    }

    function _spend(address from, uint value) internal virtual {
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];

            if (allowed != type(uint256).max) {
                allowance[from][msg.sender] = allowed - value;
            }
        }
    }

    function _domainseparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string s,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}
