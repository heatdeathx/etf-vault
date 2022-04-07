// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "../interfaces/IERC20.sol";

library SafeTransfer {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "SafeTransferFailed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "SafeTransferFailed");
    }
}
