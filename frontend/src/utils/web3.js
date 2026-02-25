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

export const checkConnection = async () => {
  // 1. 如果没有安装 MetaMask，直接返回 null
  if (!window.ethereum) return null;
  
  try {
    // 2. 静默获取已授权的账号列表（不弹窗）
    const accounts = await window.ethereum.request({ method: 'eth_accounts' });
    
    // 3. 如果数组里有账号，说明用户之前连接过
    if (accounts.length > 0) {
      // 悄悄地把 provider 和 contract 重新初始化好，防止主页报错
      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
      
      // 返回用户的钱包地址
      return accounts[0];
    }
  } catch (error) {
    console.error("静默检查连接状态失败:", error);
  }
  
  return null; // 没连过就返回 null
};