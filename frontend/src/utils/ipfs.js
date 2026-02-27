export const getIpfsUrl = (cid) => {
  if (!cid) return '';
  const gateway = import.meta.env.VITE_IPFS_GATEWAY || 'https://gateway.pinata.cloud/ipfs/';
  const baseUrl = gateway.endsWith('/') ? gateway : `${gateway}/`;
  
  return `${baseUrl}${cid}`;
};