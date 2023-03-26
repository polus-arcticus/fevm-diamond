/* global ethers describe before it */
const { deployDiamond } = require('../scripts/deploy.js')
const exampleFile = require('./lighthouse.storage.json')
const CID = require('cids')

describe('Deal Proposal', async (accounts) => {
  
  let diamondAddress
  let simpleCoinAddress
  let dealClientFacet
  before(async () => {
    ({ diamond: diamondAddress, simpleCoin: simpleCoinAddress } = await deployDiamond())
    dealClientFacet = await ethers.getContractAt('DealClientFacet', diamondAddress)

  })

  it('should be able to make a deal proposal', async () => {
    // parse cid
    const cidHex = '0x' + new CID(exampleFile.piece_CID).toString('base16').substring(1)

    const verified = (true).toString()
    const skipIpniAnnounce = (true).toString()
    const removeUnsealedCopy = (true).toString()

    const extraParamsV1 = [
      exampleFile.car_Link,
      exampleFile.car_Size,
      skipIpniAnnounce,
      removeUnsealedCopy
    ]
    const dealRequestStruct = [
      cidHex,
      exampleFile.piece_Size,
      verified,
      exampleFile.piece_CID,
      520000,
      1555200,
      0, // storage price per epoch
      0, // provider collateral
      0, // client collateral
      1, // extraparams version
      extraParamsV1
    ]

    const tx = await dealClientFacet.makeDealProposal(dealRequestStruct)
    const receipt = await tx.wait()
    const deal = await dealClientFacet.getDealProposal(receipt.events[0].topics[1])

    console.log('deal', deal)
    console.log('----------')
    console.log('deal', deal.substring(0, 42))
    console.log(cidHex)
    console.log(deal.substring(43, 83))
  })
})
