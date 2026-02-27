// 1. 显式导入 ethers 插件
import "@nomicfoundation/hardhat-ethers";

// 2. 导出配置
/** @type import('hardhat/config').HardhatUserConfig */
export default {
  solidity: {
    version: "0.8.33", // 保持版本号不变
    settings: {
      optimizer: {
        enabled: true,
        runs: 200 // 运行次数，200是默认推荐值。如果之后合约还超标，可以把这个值调小（比如 20）
      }
    }
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545" // 指向你本地的虚拟节点
    }
  }
};