task(
  'get-deal-proposal',
  'Gets a deal proposal from the proposal id'
)
  .addParam('contract', 'The address of the deal client solidity')
  .addParam('proposalId', 'The proposal ID')
  .setAction(async (taskArgs) => {
    const accounts = await ethers.getSigners()
    const contractAddr = taskArgs.contract
    const proposalID = Number(taskArgs.proposalId)
    const networkId = network.name
    console.log('Getting deal proposal on network', networkId)
    //create a new wallet instance
    //const wallet = new ethers.Wallet(accounts[0].address, ethers.provider)
    //create a DealClient contract factory
    const DealClient = await ethers.getContractAt('DealClientFacet', accounts[0])
    //create a DealClient contract instance 
    //this is what you will call to interact with the deployed contract
    const dealClient = await DealClient.attach(contractAddr)

    //send a transaction to call makeDealProposal() method
    //transaction = await dealClient.getDealProposal(proposalID)
    let result = await dealClient.getDealProposal(
      ethers.utils.hexZeroPad(ethers.utils.hexlify(proposalID), 32)
    )
    console.log('The deal proposal is:', result)
  })
