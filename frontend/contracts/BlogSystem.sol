// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import "./BlogToken.sol";


// ============ 博客系统合约 ============
contract BlogSystem is BlogToken {

    struct User {
        uint[] purchasedBlogs;  // 已购买的文章ID列表
        uint[] publishedBlogs;  // 已发布的文章ID列表
    }

    struct Blog {
        address owner;          // 博客所有者
        string name;            // 文章名称
        string intro;           // 文章简介
        string ipfsCID;         // 文章内容 (IPFS哈希)
        uint256 price;          // 购买价格（单位：BLG代币）
        uint256 viewCount;      // 浏览量
        uint256 publishDate;    // 发布日期（时间戳）
        uint256 commentCount;   // 评论数量
        mapping(uint256 => Comment) comments; // 评论列表
    }

    struct Comment {
        address buyer;  // 评论者
        uint256 date;   // 评论日期（时间戳）
        string content; // 评论内容
    }

    // 投票违规
    struct Proposal {
        uint256 blogId;      // 提议隐藏的博客ID
        address proposer;    // 提案人
        string reason;       // 提案理由
        uint256 votesFor;    // 赞成票数（以代币余额为权重）
        uint256 endTime;     // 投票截止时间
        bool executed;       // 提案是否已执行
    }

    // ============ 状态变量 ============
    Blog[] public blogs; 
    mapping(address => User) private userPool; 

    // 已购买已浏览
    mapping(address => mapping(uint256 => bool)) public hasPurchased;
    mapping(address => mapping(uint256 => bool)) public hasViewed;

    // 每日代币
    mapping(address => uint256) public lastFaucetTime;
    uint256 public constant FAUCET_AMOUNT = 100 * 10**18; 
    uint256 public constant FAUCET_COOLDOWN = 24 hours;   

    // --- DAO 治理状态变量 ---
    mapping(uint256 => Proposal) public proposals; // 提案列表
    uint256 public proposalCount;                  // 提案总数
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // 记录用户是否已对某提案投票
    mapping(uint256 => bool) public isBlogHidden;  // 记录博客是否被社区投票隐藏
    
    uint256 public constant VOTING_DURATION = 3 days;         // 投票期
    uint256 public constant QUORUM_VOTES = 500 * 10**18;      // 达成共识的最低票数阈值

    // ============ 事件定义 ============
    event BlogPublished(address indexed author, uint256 indexed blogId, string ipfsCID, string name);
    event BlogPurchased(address indexed buyer, uint256 indexed blogId, uint256 price);
    event BlogViewed(uint256 indexed blogId, uint256 newViewCount, address viewer);
    event CommentAdded(uint256 indexed blogId, uint256 indexed commentId, address indexed buyer);
    event FaucetClaimed(address indexed user, uint256 amount);
    
    // DAO 事件
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed blogId, address proposer, string reason);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, uint256 indexed blogId, bool isHidden);


    // ============ 水龙头功能 ============
    function claimTokens() public {
        require(block.timestamp >= lastFaucetTime[msg.sender] + FAUCET_COOLDOWN, "24 hours");
        lastFaucetTime[msg.sender] = block.timestamp;
        _mint(msg.sender, FAUCET_AMOUNT);
        emit FaucetClaimed(msg.sender, FAUCET_AMOUNT);
    }

    // ============ 博客核心功能 ============
    function publishBlog(
        string calldata name,
        string calldata intro,
        string calldata ipfsCID,
        uint256 price
    ) public returns (uint256 blogId, string memory cid) {
        require(bytes(name).length > 0, "name empty");
        require(bytes(ipfsCID).length > 0, "ipfsCID empty");

        blogId = blogs.length;
        Blog storage newBlog = blogs.push();
        newBlog.owner = msg.sender;
        newBlog.name = name;
        newBlog.intro = intro;
        newBlog.ipfsCID = ipfsCID; 
        newBlog.price = price;
        newBlog.viewCount = 0;
        newBlog.publishDate = block.timestamp;
        newBlog.commentCount = 0;

        userPool[msg.sender].publishedBlogs.push(blogId);

        emit BlogPublished(msg.sender, blogId, ipfsCID, name);
        return (blogId, ipfsCID);
    }

    function purchaseBlog(uint256 blogId) public {
        require(blogId < blogs.length, "blog not exist");
        require(!isBlogHidden[blogId], "Blog is hidden by community"); // DAO 拦截

        Blog storage blog = blogs[blogId];
        require(blog.owner != msg.sender, "can't buy self");
        require(!hasPurchased[msg.sender][blogId], "already purchased");

        uint256 price = blog.price;
        if (price > 0) {
            _transfer(msg.sender, blog.owner, price);
        }

        hasPurchased[msg.sender][blogId] = true;
        userPool[msg.sender].purchasedBlogs.push(blogId);
        emit BlogPurchased(msg.sender, blogId, price);
    }

    function viewBlog(uint256 blogId) public {
        require(blogId < blogs.length, "blog not exist");
        require(!isBlogHidden[blogId], "Blog is hidden by community"); // DAO 拦截
        
        if (!hasViewed[msg.sender][blogId]) {
            hasViewed[msg.sender][blogId] = true;
            blogs[blogId].viewCount += 1;
            emit BlogViewed(blogId, blogs[blogId].viewCount, msg.sender);
        }
    }

    function addComment(uint256 blogId, string calldata content) public returns (uint256) {
        require(blogId < blogs.length, "Blog does not exist");
        require(!isBlogHidden[blogId], "Blog is hidden by community"); // DAO 拦截
        require(bytes(content).length > 0, "Comment empty");
        
        Blog storage blog = blogs[blogId];
        bool isPurchased = hasPurchased[msg.sender][blogId];
        require(isPurchased || msg.sender == blog.owner, "Only buyers or owner can comment");

        uint256 commentId = blog.commentCount;
        blog.comments[commentId] = Comment({
            buyer: msg.sender,
            date: block.timestamp,
            content: content
        });
        blog.commentCount += 1;

        emit CommentAdded(blogId, commentId, msg.sender);
        return commentId;
    }

    // ============ DAO 社区治理功能 ============

    /**
     * @dev 发起隐藏违规博客的提案
     * @param blogId 涉嫌违规的博客ID
     * @param reason 举报理由
     */
    function createHideProposal(uint256 blogId, string calldata reason) public {
        require(blogId < blogs.length, "Blog does not exist");
        require(!isBlogHidden[blogId], "Blog is already hidden");
        
        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            blogId: blogId,
            proposer: msg.sender,
            reason: reason,
            votesFor: 0,
            endTime: block.timestamp + VOTING_DURATION,
            executed: false
        });

        emit ProposalCreated(proposalId, blogId, msg.sender, reason);
    }

    /**
     * @dev 社区成员对提案进行投票 (权重为持有的 BLG 代币数量)
     * @param proposalId 提案ID
     */
    function voteOnProposal(uint256 proposalId) public {
        require(proposalId < proposalCount, "Proposal does not exist");
        Proposal storage p = proposals[proposalId];
        
        require(block.timestamp < p.endTime, "Voting period has ended");
        require(!hasVotedOnProposal[proposalId][msg.sender], "You have already voted");
        
        // 获取用户的代币余额作为投票权重
        uint256 weight = balanceOf(msg.sender);
        require(weight > 0, "You need BLG tokens to vote");
        
        p.votesFor += weight;
        hasVotedOnProposal[proposalId][msg.sender] = true;

        emit Voted(proposalId, msg.sender, weight);
    }

    /**
     * @dev 执行提案 (如果投票期结束且票数达标，则隐藏博客)
     * @param proposalId 提案ID
     */
    function executeProposal(uint256 proposalId) public {
        require(proposalId < proposalCount, "Proposal does not exist");
        Proposal storage p = proposals[proposalId];
        
        require(block.timestamp >= p.endTime, "Voting is still ongoing");
        require(!p.executed, "Proposal already executed");
        
        p.executed = true;
        
        // 如果赞成票达到设定的最低阈值
        bool hidden = false;
        if (p.votesFor >= QUORUM_VOTES) {
            isBlogHidden[p.blogId] = true;
            hidden = true;
        }

        emit ProposalExecuted(proposalId, p.blogId, hidden);
    }

    // ============ 查询与数据获取 ============
    
    function getComment(uint256 blogId, uint256 commentId) public view returns (address buyer, uint256 date, string memory content) {
        require(blogId < blogs.length, "Blog does not exist");
        Blog storage blog = blogs[blogId];
        require(commentId < blog.commentCount, "Comment does not exist");
        Comment storage comment = blog.comments[commentId];
        return (comment.buyer, comment.date, comment.content);
    }

    function getUserPurchasedBlogs(address user) public view returns (uint[] memory) {
        return userPool[user].purchasedBlogs;
    }

    function getUserPublishedBlogs(address user) public view returns (uint[] memory) {
        return userPool[user].publishedBlogs;
    }

    struct BlogDetail {
        address owner;
        string name;
        string intro;
        string ipfsCID;
        uint256 price;
        uint256 viewCount;
        uint256 publishDate;
        bool isHidden;
    }

    function getBlogDetail(uint256 blogId) public view returns (BlogDetail memory) {
        require(blogId < blogs.length, "blog not exist");
        Blog storage b = blogs[blogId];
        
        return BlogDetail({
            owner: b.owner,
            name: b.name,
            intro: b.intro,
            ipfsCID: b.ipfsCID,
            price: b.price,
            viewCount: b.viewCount,
            publishDate: b.publishDate,
            isHidden: isBlogHidden[blogId]
        });
    }
}