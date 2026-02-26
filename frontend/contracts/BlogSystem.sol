// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import "./BlogDAO.sol";

// ============ 主入口：博客核心系统 ============
contract BlogSystem is BlogDAO {

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
        require(!isBlogHidden[blogId], "Blog is hidden by community");

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
        require(!isBlogHidden[blogId], "Blog is hidden by community");
        
        if (!hasViewed[msg.sender][blogId]) {
            hasViewed[msg.sender][blogId] = true;
            blogs[blogId].viewCount += 1;
            emit BlogViewed(blogId, blogs[blogId].viewCount, msg.sender);
        }
    }

    function addComment(uint256 blogId, string calldata content) public returns (uint256) {
        require(blogId < blogs.length, "Blog does not exist");
        require(!isBlogHidden[blogId], "Blog is hidden by community");
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

    function getBlogCount() public view returns (uint256) {
        return blogs.length;
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