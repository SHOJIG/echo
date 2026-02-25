import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '../config/constants';

let provider;
let signer;
let contract;

export const initWeb3 = async () => {
  // 检查浏览器是否安装了 MetaMask
  if (!window.ethereum) {
    alert("请先安装 MetaMask 钱包插件！");
    throw new Error("MetaMask not found");
  }
  
  // 连接 MetaMask
  provider = new ethers.BrowserProvider(window.ethereum);
  signer = await provider.getSigner();
  
  // 实例化合约
  contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
  
  return { provider, signer, contract };
};

// 获取已连接的合约实例
export const getContract = () => {
  if (!contract) {
    throw new Error("请先连接钱包！");
  }
  return contract;
};