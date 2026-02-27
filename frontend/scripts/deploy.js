import { ethers } from "ethers";
import fs from "fs";

async function main() {
  const rawData = fs.readFileSync("./artifacts/contracts/BlogSystem.sol/BlogSystem.json");
  const contractJson = JSON.parse(rawData);
  const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
  const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  const wallet = new ethers.Wallet(privateKey, provider);
  const factory = new ethers.ContractFactory(contractJson.abi, contractJson.bytecode, wallet);
  const contract = await factory.deploy();
  await contract.waitForDeployment();
  const address = await contract.getAddress();
  console.log(`部署成功！你的合约地址是: ${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});