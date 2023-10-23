import hre from 'hardhat'

async function main() {
  const contractKtAddress =
    process.env.CONTRACT_REWARD_ADDRESS as `0x${string}`
  const staking = await hre.viem.deployContract('Staking', [contractKtAddress])

  console.log(`Deployed to ${staking.address}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
