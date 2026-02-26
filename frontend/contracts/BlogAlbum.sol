// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import "./BlogStorage.sol";

// ============ 用户与相册逻辑合约 ============
abstract contract BlogAlbum is BlogStorage {

    // --- 水龙头 ---
    function claimTokens() public {
        require(block.timestamp >= lastFaucetTime[msg.sender] + FAUCET_COOLDOWN, "24 hours");
        lastFaucetTime[msg.sender] = block.timestamp;
        _mint(msg.sender, FAUCET_AMOUNT);
        emit FaucetClaimed(msg.sender, FAUCET_AMOUNT);
    }

    // --- 用户资料 (头像与用户名) ---
    function setAvatar(string calldata cid) public {
        userPool[msg.sender].avatarCID = cid;
        emit AvatarUpdated(msg.sender, cid);
    }

    function getAvatar(address user) public view returns (string memory) {
        return userPool[user].avatarCID;
    }

    // [新增] 设置用户名
    function setUsername(string calldata name) public {
        // 限制用户名不能为空，你也可以在这里加上长度限制
        require(bytes(name).length > 0, "Username cannot be empty");
        userPool[msg.sender].username = name;
        emit UsernameUpdated(msg.sender, name);
    }

    // [新增] 获取用户名
    function getUsername(address user) public view returns (string memory) {
        return userPool[user].username;
    }

    // --- 相册 ---
    function createAlbum(string calldata name) public returns (uint256) {
        require(bytes(name).length > 0, "Album name cannot be empty");
        
        uint256 albumId = albums.length;
        Album storage newAlbum = albums.push();
        newAlbum.owner = msg.sender;
        newAlbum.name = name;
        newAlbum.createdAt = block.timestamp;

        userAlbumsList[msg.sender].push(albumId);
        emit AlbumCreated(msg.sender, albumId, name);
        return albumId;
    }

    function addPicture(uint256 albumId, string calldata ipfsCID) public {
        require(albumId < albums.length, "Album does not exist");
        require(bytes(ipfsCID).length > 0, "Image CID cannot be empty");
        
        Album storage album = albums[albumId];
        require(album.owner == msg.sender, "Only owner can add pictures");

        uint256 picIndex = album.pictures.length;
        album.pictures.push(Picture({
            ipfsCID: ipfsCID,
            isDeleted: false,
            addedAt: block.timestamp
        }));
        emit PictureAdded(albumId, picIndex, ipfsCID);
    }

    function deletePicture(uint256 albumId, uint256 pictureIndex) public {
        require(albumId < albums.length, "Album does not exist");
        Album storage album = albums[albumId];
        require(album.owner == msg.sender, "Only owner can delete pictures");
        require(pictureIndex < album.pictures.length, "Picture does not exist");
        require(!album.pictures[pictureIndex].isDeleted, "Picture already deleted");

        album.pictures[pictureIndex].isDeleted = true;
        emit PictureDeleted(albumId, pictureIndex);
    }

    function getAlbumCover(uint256 albumId) public view returns (string memory) {
        require(albumId < albums.length, "Album does not exist");
        Album storage album = albums[albumId];

        for (uint256 i = 0; i < album.pictures.length; i++) {
            if (!album.pictures[i].isDeleted) {
                return album.pictures[i].ipfsCID;
            }
        }
        return ""; 
    }

    function getAlbumVisiblePictures(uint256 albumId) public view returns (string[] memory) {
        require(albumId < albums.length, "Album does not exist");
        Album storage album = albums[albumId];

        uint256 visibleCount = 0;
        for (uint256 i = 0; i < album.pictures.length; i++) {
            if (!album.pictures[i].isDeleted) {
                visibleCount++;
            }
        }

        string[] memory visiblePictures = new string[](visibleCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < album.pictures.length; i++) {
            if (!album.pictures[i].isDeleted) {
                visiblePictures[currentIndex] = album.pictures[i].ipfsCID;
                currentIndex++;
            }
        }
        return visiblePictures;
    }

    function getUserAlbums(address user) public view returns (uint256[] memory) {
        return userAlbumsList[user];
    }
}