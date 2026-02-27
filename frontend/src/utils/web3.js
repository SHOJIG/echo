import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '../config/constants';

let provider;
let signer;
let contract;

export const initWeb3 = async () => {
  if (!window.ethereum) {
    alert("请先安装 MetaMask 钱包插件！");
    throw new Error("MetaMask not found");
  }
  provider = new ethers.BrowserProvider(window.ethereum);
  signer = await provider.getSigner();
  contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
  
  return { provider, signer, contract };
};
export const getContract = () => {
  if (!contract) {
    throw new Error("请先连接钱包！");
  }
  return contract;
};

export const checkConnection = async () => {
  if (!window.ethereum) return null;
  
  try {
    const accounts = await window.ethereum.request({ method: 'eth_accounts' });
    if (accounts.length > 0) {
      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
      return accounts[0];
    }
  } catch (error) {
    console.error("静默检查连接状态失败:", error);
  }
  
  return null;
};