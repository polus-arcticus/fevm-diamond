# Fevm Diamond
WIP//
Going to expose the Fevm hardhat deal client and subsequent contracts through an EIP-2535 diamond.  Given its API's are beta and currently unstable, it may be wise to use an upgradable proxy for a project.  With Diamonds one can append new functions, and with a depecreciation modifer, depreciate old functions

## Capacity Futures

The cost of storage on the filecoin network is not a fixed price.  Given a use case, it may be more desirable to purchase a storage capacity for future delivery on a fixed date.  Whether it is a group of individuals wishing to coordinating the creation of a decentralized database of unknown size and sharing the costs, An agent with alot of data wishes to hedge their storage costs, or simply a degen speculator wishing to price the future storage price expectations.  The demand for a capacity options market is likely going to be robust

This project is an experiment into how a futures market with physical delivery of a storage commitment could be construed over the filecoin virtual machine.

Given that filecoin possesses an incentive structure for both storage and retriveal, i can see the case that hedging retreival capacity to handle predicitable bandwith fluctuations, it is natural to salivate at this options market.  However, this project will focus first on the capacity futures

Currently the filecoin network supports a notion of capacity commitments.  It is this primitive that we will seek to supply for a future date at an options price

### MinerApi

The cost of sealing capacity is dynamic.  Thus making a capacity commitment forward in time will likely require a margin that would cover the costs of sealing at delivery time 

case 1)  
