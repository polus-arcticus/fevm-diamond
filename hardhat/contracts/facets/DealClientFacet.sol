
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import { AppStorage, LibAppStorage } from  "../libraries/LibAppStorage.sol";
import {MarketAPI} from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import {CommonTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import {MarketTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import {AccountTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/AccountTypes.sol";
import {CommonTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import {AccountCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/AccountCbor.sol";
import {MarketCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/MarketCbor.sol";
import {BytesCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/BytesCbor.sol";
import {CBOR} from "solidity-cborutils/contracts/CBOR.sol";
import {Misc} from "@zondax/filecoin-solidity/contracts/v0.8/utils/Misc.sol";
import {FilAddresses} from "@zondax/filecoin-solidity/contracts/v0.8/utils/FilAddresses.sol";
import {Types} from "../libraries/Types.sol";
import {MarketDealNotifyParams, Status, RequestId, RequestIdx, ProviderSet, DealRequest, ExtraParamsV1} from '../libraries/LibAppStorage.sol';

import { DealClientUtilsFacet } from './DealClientUtilsFacet.sol';
import 'hardhat/console.sol';
contract DealClientFacet {
  using CBOR for CBOR.CBORBuffer;
  using AccountCBOR for *;
  using MarketCBOR for *;

  event DealProposalCreate(
    bytes32 indexed id,
    uint64 size,
    bool indexed verified,
    uint256 price
  );

  function getProviderSet(
    bytes calldata cid
  ) external view returns (ProviderSet memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    return s.pieceProviders[cid];
  }

  function getProposalIdSet(
    bytes calldata cid
  ) external view returns (RequestId memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    return s.pieceRequests[cid];
  }

  function dealsLength() external view returns (uint256) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    return s.dealRequests.length;
  }

  function getDealByIndex(
    uint256 index
  ) external view returns (DealRequest memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    return s.dealRequests[index];
  }

  function makeDealProposal(
    DealRequest calldata deal
  ) external returns (bytes32) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(msg.sender == s.owner);

    if (s.pieceStatus[deal.piece_cid] == Status.DealPublished ||
        s.pieceStatus[deal.piece_cid] == Status.DealActivated) {
      revert("deal with this pieceCid already published");
    }

    uint256 index = s.dealRequests.length;
    s.dealRequests.push(deal);

    // creates a unique ID for the deal proposal -- there are many ways to do this
    bytes32 id = keccak256(
      abi.encodePacked(block.timestamp, msg.sender, index)
    );
    s.dealRequestIdx[id] = RequestIdx(index, true);

    s.pieceRequests[deal.piece_cid] = RequestId(id, true);
    s.pieceStatus[deal.piece_cid] = Status.RequestSubmitted;

    // writes the proposal metadata to the event log
    emit DealProposalCreate(
      id,
      deal.piece_size,
      deal.verified_deal,
      deal.storage_price_per_epoch
    );

    return id;
  }


  // Returns a CBOR-encoded DealProposal.
  function getDealProposal(
    bytes32 proposalId
  ) external view returns (bytes memory) {
    console.log('hi');
    AppStorage storage s = LibAppStorage.diamondStorage();
    DealRequest memory deal = DealClientUtilsFacet(address(this)).getDealRequest(proposalId);

    MarketTypes.DealProposal memory ret;
    ret.piece_cid = CommonTypes.Cid(deal.piece_cid);
    ret.piece_size = deal.piece_size;
    ret.verified_deal = deal.verified_deal;
    ret.client = DealClientUtilsFacet(address(this)).getDelegatedAddress(address(this));
    // Set a dummy provider. The provider that picks up this deal will need to set its own address.
    ret.provider = FilAddresses.fromActorID(0);
    
    ret.label = CommonTypes.DealLabel(bytes(deal.label), true);
    ret.start_epoch = CommonTypes.ChainEpoch.wrap(deal.start_epoch);
    ret.end_epoch = CommonTypes.ChainEpoch.wrap(deal.end_epoch);
   
    ret.storage_price_per_epoch = Types.uintToBigInt(
      deal.storage_price_per_epoch
    );
    ret.provider_collateral = Types.uintToBigInt(deal.provider_collateral);
    ret.client_collateral = Types.uintToBigInt(deal.client_collateral);

    return Types.serializeDealProposal(ret);
  }





  // This function can be called/smartly polled to retrieve the deal activation status
  // associated with provided pieceCid and update the contract state based on that
  // info
  // @pieceCid - byte representation of pieceCid
  function updateActivationStatus(bytes memory pieceCid) external {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(s.pieceDeals[pieceCid] > 0, "no deal published for this piece cid");

    MarketTypes.GetDealActivationReturn memory ret = MarketAPI.getDealActivation(s.pieceDeals[pieceCid]);
    if (CommonTypes.ChainEpoch.unwrap(ret.terminated) > 0) {
      s.pieceStatus[pieceCid] = Status.DealTerminated;
    } else if (CommonTypes.ChainEpoch.unwrap(ret.activated) > 0) {
      s.pieceStatus[pieceCid] = Status.DealActivated;
    }
  }

  // addBalance funds the builtin storage market actor's escrow
  // with funds from the contract's own balance
  // @value - amount to be added in escrow in attoFIL
  function addBalance(uint256 value) external {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(msg.sender == s.owner);
    MarketAPI.addBalance(DealClientUtilsFacet(address(this)).getDelegatedAddress(address(this)), value);
  }


  // This function attempts to withdraw the specified amount from the contract addr's escrow balance
  // If less than the given amount is available, the full escrow balance is withdrawn
  // @client - Eth address where the balance is withdrawn to. This can be the contract address or an external address
  // @value - amount to be withdrawn in escrow in attoFIL
  function withdrawBalance(
    address client,
    uint256 value
  ) external returns (uint) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(msg.sender == s.owner);

    MarketTypes.WithdrawBalanceParams memory params = MarketTypes
    .WithdrawBalanceParams(
      DealClientUtilsFacet(address(this)).getDelegatedAddress(client),
      Types.uintToBigInt(value)
    );
    CommonTypes.BigInt memory ret = MarketAPI.withdrawBalance(params);

    return Types.bigIntToUint(ret);
  }



}
