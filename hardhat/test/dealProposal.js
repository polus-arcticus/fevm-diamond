/* global ethers describe before it */
const { deployDiamond } = require('../scripts/deploy.js')
const exampleFile = require('./lighthouse.storage.json')
const CID = require('cids')
async function getHelia () {
  const { base16 } = await import('multiformats/bases/base16')
  const { createHelia } = await import('helia')
  const { createLibp2p } = await import('libp2p')
  const { noise } = await import('@chainsafe/libp2p-noise')
  const { yamux } = await import('@chainsafe/libp2p-yamux')
  const { webSockets } = await import('@libp2p/websockets')
  const { bootstrap } = await import('@libp2p/bootstrap')
  const { unixfs } = await import('@helia/unixfs')
  const { MemoryBlockstore } = await import('blockstore-core')
  const { MemoryDatastore } = await import('datastore-core')
  const blockstore = new MemoryBlockstore()
  const datastore = new MemoryDatastore()
  const libp2p = await createLibp2p({
    datastore,
    transports: [
      webSockets()
    ],
    connectionEncryption: [
      noise()
    ],
    streamMuxers: [
      yamux()
    ],
    peerDiscovery: [
      bootstrap({
        list: [
          '/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN',
          '/dnsaddr/bootstrap.libp2p.io/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa',
          '/dnsaddr/bootstrap.libp2p.io/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb',
          '/dnsaddr/bootstrap.libp2p.io/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt'
        ]
      })
    ]
  })

  // create a Helia node
  const helia = await createHelia({
    datastore,
    blockstore,
    libp2p
  })

  const fs = unixfs(helia)

  return { CID, helia, fs, base16 }
}


describe('Deal Proposal', async (accounts) => {
  
  let diamondAddress
  let simpleCoinAddress
  let dealClientFacet
  let heliaInstance
  let fs
  let CID
  let base16
  before(async () => {
    ({ helia: heliaInstance, fs, CID, base16 } = await getHelia());

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

    console.log(receipt.events[0])

    const deal = await dealClientFacet.getDealProposal(receipt.events[0].topics[1])
    console.log(deal)


  })
})
