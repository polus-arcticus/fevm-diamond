pragma solidity ^0.8.17;
import {AppStorage, LibAppStorage} from '../libraries/LibAppStorage.sol';
import {MarketAPI} from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import {MarketTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import {CommonTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";

contract FilecoinMarketConsumerFacet {
  function storeAll(uint64 dealId) public {
    storeDealLabel(dealId);
    storeDealClient(dealId);
    storeDealClientProvider(dealId);
    storeDealCommitment(dealId);
    storeDealTerm(dealId);
    storeDealTotalPrice(dealId);
    storeClientCollateral(dealId);
    storeProviderCollateral(dealId);
    storeDealVerificaton(dealId);
    storeDealActivationStatus(dealId);
  } 

  function storeDealLabel(uint64 dealId) public  {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.dealLabel = MarketAPI.getDealLabel(dealId);
  }

  function storeDealClient(uint64 dealId) public {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.dealClientActorId = MarketAPI.getDealClient(dealId);
  }

  function storeDealClientProvider(uint64 dealId) public {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.dealProviderActorId = MarketAPI.getDealProvider(dealId);
  }

  function storeDealCommitment(uint64 dealId) public {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.dealCommitment = MarketAPI.getDealDataCommitment(dealId);
  }

  function storeDealTerm(uint64 dealId) public {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.dealTerm = MarketAPI.getDealTerm(dealId);
  }

  function storeDealTotalPrice(uint64 dealId) public {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.dealPricePerEpoch = MarketAPI.getDealTotalPrice(dealId);
  }

  function storeClientCollateral(uint64 dealId) public {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.clientCollateral = MarketAPI.getDealClientCollateral(dealId);
  }

  function storeProviderCollateral(uint64 dealId) public {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.providerCollateral = MarketAPI.getDealProviderCollateral(dealId);
  }

  function storeDealVerificaton(uint64 dealId) public {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.isDealActivated = MarketAPI.getDealVerified(dealId);
  }

  function storeDealActivationStatus(uint64 dealId) public {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.activationStatus = MarketAPI.getDealActivation(dealId);
  }
}
