/* global ethers describe before it */

const { deployDiamond } = require('../scripts/deploy.js')

async function getHelia () {
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

  return { helia, fs }
}


describe('Deal Proposal', async (accounts) => {
  let diamondAddress
  let simpleCoinAddress
  let dealClientFacet
  let heliaInstance
  let fs
  before(async () => {
    ({ helia: heliaInstance, fs } = await getHelia());

    ({ diamond: diamondAddress, simpleCoin: simpleCoinAddress } = await deployDiamond())
    dealClientFacet = await ethers.getContractAt('DealClientFacet', diamondAddress)

  })

  it('should be able to make a deal proposal', async () => {

  })
})
