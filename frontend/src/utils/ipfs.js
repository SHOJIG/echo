/**
 * 将 IPFS CID 转换为可访问的 HTTP 链接
 * 优先使用环境变量配置的网关，如果没有配置则降级使用默认的 Pinata 网关
 * * @param {string} cid - 文件的 IPFS Hash
 * @returns {string} 完整的 HTTP URL
 */
export const getIpfsUrl = (cid) => {
  if (!cid) return '';
  
  // 获取环境变量中的网关配置
  const gateway = import.meta.env.VITE_IPFS_GATEWAY || 'https://gateway.pinata.cloud/ipfs/';
  
  // 兼容处理：确保网关地址末有尾斜杠
  const baseUrl = gateway.endsWith('/') ? gateway : `${gateway}/`;
  
  return `${baseUrl}${cid}`;
};