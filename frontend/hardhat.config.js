// 1. 显式导入 ethers 插件，这样 Hardhat 运行环境 (hre) 才能找到它
import "@nomicfoundation/hardhat-ethers";

// 2. 导出配置
/** @type import('hardhat/config').HardhatUserConfig */
export default {
  solidity: "0.8.33", // 确保和合约里的版本号一致
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545" // 指向你本地的虚拟节点
    }
  }
};