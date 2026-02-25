// 合约地址
export const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

// 提取你合约中需要用到的核心 ABI (这里做了精简，实际可以直接把 Remix 里的 ABI 完整复制过来)
export const CONTRACT_ABI = [
  // 水龙头
  "function claimTokens() public",
  // 核心功能
  "function publishBlog(string calldata name, string calldata intro, string calldata ipfsCID, uint256 price) public returns (uint256, string)",
  "function purchaseBlog(uint256 blogId) public",
  "function viewBlog(uint256 blogId) public",
  "function addComment(uint256 blogId, string calldata content) public returns (uint256)",
  // 查询功能
  "function balanceOf(address account) public view returns (uint256)",
  "function hasPurchased(address, uint256) public view returns (bool)",
  "function getBlogDetail(uint256 blogId) public view returns (address owner, string memory name, string memory intro, string memory ipfsCID, uint256 price, uint256 viewCount, uint256 publishDate, bool isHidden)",
  "function getUserPublishedBlogs(address user) public view returns (uint256[] memory)",
  // DAO 治理
  "function createHideProposal(uint256 blogId, string calldata reason) public",
  "function voteOnProposal(uint256 proposalId) public",
  "function executeProposal(uint256 proposalId) public"
];