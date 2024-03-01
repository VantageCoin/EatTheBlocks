// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

contract Voter {
    
struct Candidate { 
   uint id;
   string name;
   uint voteCount;
}

mapping (uint => Candidate) public candidates;
mapping(address => bool) public hasAlreadyVoted;
mapping(string => uint) public totalVotes;

uint[] ids;
uint256 counter = 0;

event VoterEvents(address indexed _setter, string  _value);


function setCandidate(uint id, string memory name, uint voteCnt) public {
    Candidate memory candidate = Candidate(id, name, voteCnt);
    candidates[id] = candidate;
    ids.push(id);
    ++counter;
    emit VoterEvents(msg.sender, "Candidate was added.");
   }

function castVote(string memory name) public {

    require(!hasAlreadyVoted[msg.sender], "Voter has already voted!");
    hasAlreadyVoted[msg.sender] = true;

    uint _id = 0;

    for (uint i = 0; i < ids.length; i++) {
        _id = ids[i];
        Candidate memory candidate = candidates[_id];

        if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(candidate.name))) {
            uint cnt = candidate.voteCount;
            ++cnt;
            candidate.voteCount = cnt;
            candidates[_id] = candidate;
        }
    }    

    emit VoterEvents(msg.sender, "Vote was cast.");
}

function total_Votes() public {
    uint _id = 0;

        for (uint i = 0; i < ids.length; i++) {
            _id = ids[i];
            Candidate memory candidate = candidates[_id];
            totalVotes[candidate.name] = candidate.voteCount;
        }

        emit VoterEvents(msg.sender, "Votes were totaled.");
}

}
