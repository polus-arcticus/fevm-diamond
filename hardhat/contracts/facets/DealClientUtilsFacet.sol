pragma solidity ^0.8.17;

import { AppStorage, LibAppStorage } from  "../libraries/LibAppStorage.sol";
import {CBOR} from "solidity-cborutils/contracts/CBOR.sol";
import {AccountCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/AccountCbor.sol";
import {MarketCBOR} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/MarketCbor.sol";
import {CommonTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import {MarketTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import {AccountTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/AccountTypes.sol";
import {Misc} from "@zondax/filecoin-solidity/contracts/v0.8/utils/Misc.sol";
import {Status, RequestId, RequestIdx, ProviderSet, DealRequest, ExtraParamsV1} from '../libraries/LibAppStorage.sol';
import {BigInts} from '@zondax/filecoin-solidity/contracts/v0.8/utils/BigInts.sol';
contract DealClientUtilsFacet {
  event ReceivedDataCap(string received);

  using CBOR for CBOR.CBORBuffer;
  using AccountCBOR for *;
  using MarketCBOR for *;

  // TODO fix in filecoin-solidity. They're using the wrong hex value.
  function serializeExtraParamsV1(
    ExtraParamsV1 memory params
  ) pure public returns (bytes memory) {
    CBOR.CBORBuffer memory buf = CBOR.create(64);
    buf.startFixedArray(4);
    buf.writeString(params.location_ref);
    buf.writeUInt64(params.car_size);
    buf.writeBool(params.skip_ipni_announce);
    buf.writeBool(params.remove_unsealed_copy);
    return buf.data();
  }
  function getExtraParams(
    bytes32 proposalId
  ) external view returns (bytes memory extra_params) {
    DealRequest memory deal = getDealRequest(proposalId);
    return serializeExtraParamsV1(deal.extra_params);
  }
  // helper function to get deal request based from id
  function getDealRequest(
    bytes32 requestId
  ) public view returns (DealRequest memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    RequestIdx memory ri = s.dealRequestIdx[requestId];
    require(ri.valid, "proposalId not available");
    return s.dealRequests[ri.idx];
  }

  // dealNotify is the callback from the market actor into the contract at the end
  // of PublishStorageDeals. This message holds the previously approved deal proposal
  // and the associated dealID. The dealID is stored as part of the contract state
  // and the completion of this call marks the success of PublishStorageDeals
  // @params - cbor byte array of MarketDealNotifyParams
  function dealNotify(bytes memory params) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(
      msg.sender == s.MARKET_ACTOR_ETH_ADDRESS,
      "msg.sender needs to be market actor f05"
    );

    MarketTypes.MarketDealNotifyParams memory mdnp = MarketCBOR.deserializeMarketDealNotifyParams(
      params
    );
    MarketTypes.DealProposal memory proposal = MarketCBOR.deserializeDealProposal(
      mdnp.dealProposal
    );

    // These checks prevent race conditions between the authenticateMessage and
    // marketDealNotify calls where someone could have 2 of the same deal proposals
    // within the same PSD msg, which would then get validated by authenticateMessage
    // However, only one of those deals should be allowed
    require(
      s.pieceRequests[proposal.piece_cid.data].valid,
      "piece cid must be added before authorizing"
    );
    require(
      !s.pieceProviders[proposal.piece_cid.data].valid,
      "deal failed policy check: provider already claimed this cid"
    );

    s.pieceProviders[proposal.piece_cid.data] = ProviderSet(
      proposal.provider.data,
      true
    );
    s.pieceDeals[proposal.piece_cid.data] = mdnp.dealId;
    s.pieceStatus[proposal.piece_cid.data] = Status.DealPublished;
  }

  function receiveDataCap(bytes memory params) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(
      msg.sender == s.DATACAP_ACTOR_ETH_ADDRESS,
      "msg.sender needs to be datacap actor f07"
    );
    emit ReceivedDataCap("DataCap Received!");
    // Add get datacap balance api and store datacap amount
  }

  // authenticateMessage is the callback from the market actor into the contract
  // as part of PublishStorageDeals. This message holds the deal proposal from the
  // miner, which needs to be validated by the contract in accordance with the
  // deal requests made and the contract's own policies
  // @params - cbor byte array of AccountTypes.AuthenticateMessageParams
  function authenticateMessage(bytes memory params) internal view {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(
      msg.sender == s.MARKET_ACTOR_ETH_ADDRESS,
      "msg.sender needs to be market actor f05"
    );

    AccountTypes.AuthenticateMessageParams memory amp = params
    .deserializeAuthenticateMessageParams();
    MarketTypes.DealProposal memory proposal = MarketCBOR.deserializeDealProposal(
      amp.message
    );

    bytes memory pieceCid = proposal.piece_cid.data;
    require(s.pieceRequests[pieceCid].valid, "piece cid must be added before authorizing");
    require(!s.pieceProviders[pieceCid].valid, "deal failed policy check: provider already claimed this cid");

    DealRequest memory req = DealClientUtilsFacet(address(this)).getDealRequest(s.pieceRequests[pieceCid].requestId);

    require(proposal.verified_deal == req.verified_deal, "verified_deal param mismatch");

    (uint256 proposalStoragePricePerEpoch, bool storagePriceConverted) = BigInts.toUint256(proposal.storage_price_per_epoch);
    (uint256 proposalClientCollateral, bool collateralConverted) = BigInts.toUint256(proposal.storage_price_per_epoch);
    require(storagePriceConverted && collateralConverted, "Issues converting uint256 to BigInt, may not have accurate values");
    require(proposalStoragePricePerEpoch <= req.storage_price_per_epoch, "storage price greater than request amount");
    require(proposalClientCollateral <= req.client_collateral, "client collateral greater than request amount");

  }

  // handle_filecoin_method is the universal entry point for any evm based
  // actor for a call coming from a builtin filecoin actor
  // @method - FRC42 method number for the specific method hook
  // @params - CBOR encoded byte array params
  function handle_filecoin_method(
    uint64 method,
    uint64,
    bytes memory params
  ) external returns (uint32, uint64, bytes memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    bytes memory ret;
    uint64 codec;
    // dispatch methods
    if (method == s.AUTHENTICATE_MESSAGE_METHOD_NUM) {
      authenticateMessage(params);
      // If we haven't reverted, we should return a CBOR true to indicate that verification passed.
      CBOR.CBORBuffer memory buf = CBOR.create(1);
      buf.writeBool(true);
      ret = buf.data();
      codec = Misc.CBOR_CODEC;
    } else if (method == s.MARKET_NOTIFY_DEAL_METHOD_NUM) {
      dealNotify(params);
    } else if (method == s.DATACAP_RECEIVER_HOOK_METHOD_NUM) {
      receiveDataCap(params);
    } else {
      revert("the filecoin method that was called is not handled");
    }
    return (0, codec, ret);
  }
}
