// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/******************************************************************************\
 * Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 *
 * Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import { AppStorage } from "../libraries/LibAppStorage.sol";
// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit {    
  AppStorage internal s;
  // You can add parameters to this function in order to pass in 
  // data to set your own state variables
  function init(
    address owner
  ) external {
    // adding ERC165 data
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    ds.supportedInterfaces[type(IERC165).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    ds.supportedInterfaces[type(IERC173).interfaceId] = true;

    // add your own state variables 
    // EIP-2535 specifies that the `diamondCut` function takes two optional 
    // arguments: address _init and bytes calldata _calldata
    // These arguments are used to execute an arbitrary function using delegatecall
    // in order to set state variables in the diamond during deployment or an upgrade
    // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
    s.owner = owner;
    s.AUTHENTICATE_MESSAGE_METHOD_NUM = 2643134072;
    s.DATACAP_RECEIVER_HOOK_METHOD_NUM = 3726118371;
    s.MARKET_NOTIFY_DEAL_METHOD_NUM = 4186741094;
    s.MARKET_ACTOR_ETH_ADDRESS = address(0xff00000000000000000000000000000000000005);
    s.DATACAP_ACTOR_ETH_ADDRESS = address(0xfF00000000000000000000000000000000000007);

    s.CALL_ACTOR_ID = 0xfe00000000000000000000000000000000000005;
    s.DEFAULT_FLAG = 0x00000000;
    s.METHOD_SEND = 0;
  }


}
