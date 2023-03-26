/* global ethers describe before it */
const { deployDiamond } = require('../scripts/deploy.js')
const exampleFile = require('./lighthouse.storage.json')
const CID = require('cids')

describe('Deal Proposal', async () => {
  let accounts
  let diamondAddress
  let simpleCoinAddress
  let dealRewarderFacet
  before(async () => {
    accounts = await ethers.getSigners();
    ({ diamond: diamondAddress, simpleCoin: simpleCoinAddress } = await deployDiamond())
    dealRewarderFacet = await ethers.getContractAt('DealRewarderFacet', diamondAddress)


  })

  it("Can add a CID", async () => {
    const cidHex = '0x' + new CID(exampleFile.piece_CID).toString('base16').substring(1)

    const tx = await dealRewarderFacet.addCID(cidHex, exampleFile.piece_Size)
    const receipt = await tx.wait()
  })

  it("can fund a CID", async () => {
    const tx = await dealRewarderFacet.connect(accounts[1]).fund(0, {
      value: ethers.utils.parseEther('1')
    })
    const receipt = await tx.wait()
  })

  it("can claim a bounty", async () => {
    const tx = await dealRewarderFacet.claim_bounty(0)
    const receipt = await tx.wait()
  })
})

