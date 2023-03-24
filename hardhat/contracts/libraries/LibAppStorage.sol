pragma solidity 0.8.17;
import {CommonTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import {MarketTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import { LibDiamond } from  "./LibDiamond.sol";

enum Status {
  None,
  RequestSubmitted,
  DealPublished,
  DealActivated,
  DealTerminated
}
struct RequestId {
  bytes32 requestId;
  bool valid;
}

struct RequestIdx {
  uint256 idx;
  bool valid;
}

struct ProviderSet {
  bytes provider;
  bool valid;
}

// User request for this contract to make a deal. This structure is modelled after Filecoin's Deal
// Proposal, but leaves out the provider, since any provider can pick up a deal broadcast by this
// contract.
struct DealRequest {
  bytes piece_cid;
  uint64 piece_size;
  bool verified_deal;
  string label;
  int64 start_epoch;
  int64 end_epoch;
  uint256 storage_price_per_epoch;
  uint256 provider_collateral;
  uint256 client_collateral;
  uint64 extra_params_version;
  ExtraParamsV1 extra_params;
}

// Extra parameters associated with the deal request. These are off-protocol flags that
// the storage provider will need.
struct ExtraParamsV1 {
  string location_ref;
  uint64 car_size;
  bool skip_ipni_announce;
  bool remove_unsealed_copy;
}

struct MarketDealNotifyParams {
  bytes dealProposal;
  uint64 dealId;
}

struct AppStorage {
  uint64  AUTHENTICATE_MESSAGE_METHOD_NUM;
  uint64  DATACAP_RECEIVER_HOOK_METHOD_NUM;
  uint64  MARKET_NOTIFY_DEAL_METHOD_NUM;
  address  MARKET_ACTOR_ETH_ADDRESS; 
  address  DATACAP_ACTOR_ETH_ADDRESS; 
  address  CALL_ACTOR_ID;
  uint64  DEFAULT_FLAG; 
  uint64  METHOD_SEND;

  mapping(bytes32 => RequestIdx) dealRequestIdx; // contract deal id -> deal index
  DealRequest[] dealRequests;

  mapping(bytes => RequestId) pieceRequests; // commP -> dealProposalID
  mapping(bytes => ProviderSet) pieceProviders; // commP -> provider
  mapping(bytes => uint64) pieceDeals; // commP -> deal ID
  mapping(bytes => Status) pieceStatus;

  address owner;
  mapping(bytes => bool)  cidSet;
  mapping(bytes => uint)  cidSizes;
  mapping(bytes => mapping(uint64 => bool))  cidProviders;

  CommonTypes.DealLabel  dealLabel;
  uint64  dealClientActorId;
  uint64  dealProviderActorId;
  bool  isDealActivated;
  MarketTypes.GetDealDataCommitmentReturn  dealCommitment;
  MarketTypes.GetDealTermReturn  dealTerm;
  CommonTypes.BigInt  dealPricePerEpoch;
  CommonTypes.BigInt  clientCollateral; 
  CommonTypes.BigInt  providerCollateral;
  MarketTypes.GetDealActivationReturn  activationStatus;

}

library LibAppStorage {
  function diamondStorage() internal pure returns (AppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }

  function abs(int256 x) internal pure returns (uint256) {
    return uint256(x >= 0 ? x : -x);
  }
}

contract Modifiers {
  modifier onlyDiamond() {
    require(msg.sender == address(this), "LibAppStorage: Caller Must be Diamond");
    _;
  }
  modifier onlyOwner {
    LibDiamond.enforceIsContractOwner();
    _;
  }
}
