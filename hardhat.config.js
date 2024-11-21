require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomicfoundation/hardhat-verify");

module.exports = {
  solidity: "0.8.22",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/kXaI6f_9emG_RRE6ZrXiL1JZtbFKSDDR`,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
//   etherscan: {
//     apiKey: {
//       sepolia: process.env.ETHERSCAN_API_KEY,
//     },
//   },
};