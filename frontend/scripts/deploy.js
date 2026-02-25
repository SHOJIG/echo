import { ethers } from "ethers";
import fs from "fs";

async function main() {
  console.log("🚀 启动降维打击，绕过 Hardhat 直接部署...");

  // 1. 直接读取刚才编译好的图纸文件 (ABI 和 Bytecode)
  const rawData = fs.readFileSync("./artifacts/contracts/BlogSystem.sol/BlogSystem.json");
  const contractJson = JSON.parse(rawData);

  // 2. 连接到你本地一直开着的虚拟区块链节点
  const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");

  // 3. 直接使用 Hardhat 给的第一个测试账号 (Account #0) 的固定私钥
  const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  const wallet = new ethers.Wallet(privateKey, provider);

  // 4. 组装并发送合约到区块链
  const factory = new ethers.ContractFactory(contractJson.abi, contractJson.bytecode, wallet);
  
  console.log("⏳ 正在发送交易，请稍候...");
  const contract = await factory.deploy();
  
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log(`🎉 恭喜！暴力部署成功！你的合约地址是: ${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});