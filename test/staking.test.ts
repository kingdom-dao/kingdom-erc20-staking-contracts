import {
  time,
  loadFixture,
} from '@nomicfoundation/hardhat-toolbox-viem/network-helpers'
import { expect } from 'chai'
import hre from 'hardhat'
import { getAddress, parseGwei } from 'viem'

describe('Staking', () => {
  async function deployStakingFixture() {
    const [owner, otherAccount] = await hre.viem.getWalletClients()

    const reward = await hre.viem.deployContract("ERC20Token")
    const staking = await hre.viem.deployContract('Staking', [reward.address])

    const publicClient = await hre.viem.getPublicClient()

    return {
      reward,
      staking,
      owner,
      otherAccount,
      publicClient,
    }
  }

  describe('deposit function', () => {
    it('Should set the right unlockTime', async () => {
      const { reward, staking, publicClient } = await loadFixture(deployStakingFixture)

      const isPeriod = await staking.read.isSupportedPeriod([52])
      console.log("hoge: ", isPeriod)

      await reward.write.approve([staking.address, BigInt(100)])

      await staking.write.deposit([reward.address, 1, BigInt(100)])

      expect(true).to.be.true
    })
  })
})
