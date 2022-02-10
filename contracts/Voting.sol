// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Voting is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _proposalCounter;

    uint public winningProposalId;
    WorkflowStatus private _votingStatus = WorkflowStatus.RegisteringVoters;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    mapping(address => Voter) public voters;
    mapping(uint => Proposal) public proposals;

    /*
        Modifiers
    */

    modifier requireStatus(WorkflowStatus _status) {
        require(_votingStatus == _status, string(abi.encodePacked("Require ", _getVotingStatusString(_status), " status !")));
        _;
    }

    modifier requireRegisteredVoter() {
        require(voters[msg.sender].isRegistered, string(abi.encodePacked("Not a registered voter: ", msg.sender)));
        _;
    }

    /*
        Getters
    */

    function getVotingStatus() public view returns (string memory) {
        return _getVotingStatusString(_votingStatus);
    }

    // Returns a string instead of the uint of the enumeration 
    function _getVotingStatusString(WorkflowStatus _status) internal pure returns (string memory) {
        if (_status == WorkflowStatus.ProposalsRegistrationStarted) {
            return "ProposalsRegistrationStarted";
        } else if (_status == WorkflowStatus.ProposalsRegistrationEnded) {
            return "ProposalsRegistrationEnded";
        } else if (_status == WorkflowStatus.VotingSessionStarted) {
            return "VotingSessionStarted";
        } else if (_status == WorkflowStatus.VotingSessionEnded) {
            return "VotingSessionEnded";
        } else if (_status == WorkflowStatus.VotesTallied) {
            return "VotesTallied";
        } else {
            return "RegisteringVoters";
        }
    }

    function getWinner() public view returns (Proposal memory) {
        return proposals[winningProposalId];
    }

    function getProposalCount() public view returns (uint) {
        return _proposalCounter.current();
    }
    
    /*
        Set of functions to handle participation, voting proposals and vote
    */

    // Whitelist voter with his address
    function registerVoter(address _voter) public onlyOwner requireStatus(WorkflowStatus.RegisteringVoters) {
        require(_voter != msg.sender, "Administrator cannot be a voter !");
        require(!voters[_voter].isRegistered, "Voter already registered !");
        voters[_voter] = Voter(true, false, 0);
        emit VoterRegistered(_voter);
    }

    // Add new proposal only if voter is whitelisted
    function registerProposal(string memory _proposition) public requireRegisteredVoter requireStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        _proposalCounter.increment();
        proposals[_proposalCounter.current()] = Proposal(_proposition, 0);
        emit ProposalRegistered(_proposalCounter.current());
    }

    // Voters can vote
    function vote(uint _proposalId) public requireRegisteredVoter requireStatus(WorkflowStatus.VotingSessionStarted) {
        require(_proposalId >= 1 &&  _proposalId <= _proposalCounter.current(), "Proposal not found by the given Id !");
        require(!voters[msg.sender].hasVoted, "Already voted !");
        proposals[_proposalId].voteCount += 1;
        voters[msg.sender].votedProposalId = _proposalId;
        voters[msg.sender].hasVoted = true;
        emit Voted(msg.sender, _proposalId);
    }

    // Counts all the votes and publish the result
    function countVotes() public onlyOwner requireStatus(WorkflowStatus.VotingSessionEnded) {
        uint bestVote = 0;
        
        for (uint i=1; i<_proposalCounter.current(); i++) {
            if(proposals[i].voteCount > bestVote){
                winningProposalId = i;
                bestVote = proposals[i].voteCount;
            }
        }

        _changeWorkflowStatus(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    /*
        Set of function that change the WorkflowStatus state
    */

    function _changeWorkflowStatus(WorkflowStatus _previous, WorkflowStatus _next) internal {
        _votingStatus = _next;
        emit WorkflowStatusChange(_previous, _next);
    }

    function startProposalRegistration() public onlyOwner requireStatus(WorkflowStatus.RegisteringVoters) {
        _changeWorkflowStatus(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function stopProposalRegistration() public onlyOwner requireStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        _changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession() public onlyOwner requireStatus(WorkflowStatus.ProposalsRegistrationEnded) {
        _changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function stopVotingSession() public onlyOwner requireStatus(WorkflowStatus.VotingSessionStarted) {
        _changeWorkflowStatus(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }
}