// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import "./BlogAlbum.sol";

// ============ DAO 社区治理合约 ============
abstract contract BlogDAO is BlogAlbum {

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

    function voteOnProposal(uint256 proposalId) public {
        require(proposalId < proposalCount, "Proposal does not exist");
        Proposal storage p = proposals[proposalId];
        
        require(block.timestamp < p.endTime, "Voting period has ended");
        require(!hasVotedOnProposal[proposalId][msg.sender], "You have already voted");

        uint256 weight = balanceOf(msg.sender);
        require(weight > 0, "You need BLG tokens to vote");
        
        p.votesFor += weight;
        hasVotedOnProposal[proposalId][msg.sender] = true;

        emit Voted(proposalId, msg.sender, weight);
    }

    function executeProposal(uint256 proposalId) public {
        require(proposalId < proposalCount, "Proposal does not exist");
        Proposal storage p = proposals[proposalId];
        
        require(block.timestamp >= p.endTime, "Voting is still ongoing");
        require(!p.executed, "Proposal already executed");
        
        p.executed = true;

        bool hidden = false;
        if (p.votesFor >= QUORUM_VOTES) {
            isBlogHidden[p.blogId] = true;
            hidden = true;
        }

        emit ProposalExecuted(proposalId, p.blogId, hidden);
    }
}