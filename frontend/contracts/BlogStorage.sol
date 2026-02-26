// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import "./BlogToken.sol";

// ============ 基础数据与存储合约 ============
abstract contract BlogStorage is BlogToken {

    struct User {
        uint[] purchasedBlogs;
        uint[] publishedBlogs;
        string avatarCID;        
        string username;         // [新增] 用户名
    }

    struct Blog {
        address owner;
        string name;
        string intro;
        string ipfsCID;
        uint256 price;
        uint256 viewCount;
        uint256 publishDate;
        uint256 commentCount;
        mapping(uint256 => Comment) comments;
    }

    struct Comment {
        address buyer;
        uint256 date;
        string content;
    }

    struct Proposal {
        uint256 blogId;
        address proposer;
        string reason;
        uint256 votesFor;
        uint256 endTime;
        bool executed;
    }

    struct Picture {
        string ipfsCID;
        bool isDeleted;
        uint256 addedAt;
    }

    struct Album {
        address owner;
        string name;
        uint256 createdAt;
        Picture[] pictures;
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

    // ============ 状态变量 ============
    Blog[] public blogs;
    mapping(address => User) internal userPool; 

    mapping(address => mapping(uint256 => bool)) public hasPurchased;
    mapping(address => mapping(uint256 => bool)) public hasViewed;

    mapping(address => uint256) public lastFaucetTime;
    uint256 public constant FAUCET_AMOUNT = 100 * 10**18; 
    uint256 public constant FAUCET_COOLDOWN = 24 hours;

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal;
    mapping(uint256 => bool) public isBlogHidden;
    
    uint256 public constant VOTING_DURATION = 3 days;
    uint256 public constant QUORUM_VOTES = 500 * 10**18;

    Album[] public albums;
    mapping(address => uint256[]) public userAlbumsList;

    // ============ 事件定义 ============
    event BlogPublished(address indexed author, uint256 indexed blogId, string ipfsCID, string name);
    event BlogPurchased(address indexed buyer, uint256 indexed blogId, uint256 price);
    event BlogViewed(uint256 indexed blogId, uint256 newViewCount, address viewer);
    event CommentAdded(uint256 indexed blogId, uint256 indexed commentId, address indexed buyer);
    event FaucetClaimed(address indexed user, uint256 amount);
    
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed blogId, address proposer, string reason);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, uint256 indexed blogId, bool isHidden);

    event AvatarUpdated(address indexed user, string avatarCID);
    event UsernameUpdated(address indexed user, string newUsername); // [新增] 用户名修改事件
    event AlbumCreated(address indexed owner, uint256 indexed albumId, string name);
    event PictureAdded(uint256 indexed albumId, uint256 pictureIndex, string ipfsCID);
    event PictureDeleted(uint256 indexed albumId, uint256 pictureIndex);
}