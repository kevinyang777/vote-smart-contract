// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
   
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    struct Proposal {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }
    struct User{
        uint choice;
        address wallet;
    }

    address public chairperson;
    bool public winnerChoosen;
    event Received(uint value);
  
    function deposit() public payable {
        emit Received(msg.value);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    fallback() external payable {
        emit Received(msg.value);
    }
    
    receive() external payable {
        emit Received(msg.value);
    }
    mapping(address => Voter) public voters;
    uint256 public startDate; //unix time
    uint256 public endDate; //unix time
    Proposal[] public proposals;
    User[] public users;


    // 1. The owner of the contract can input one or more choices to be voted by people
    // owner can put as many choices for the voters to vote when deploying the contract
    // 2. The owner of the contract can specify the start time and end time for the voting period.
    // owner can put start date and end date when deploying the contract
    constructor(string[] memory choices , uint256 start, uint256 end) payable{
        chairperson = msg.sender;
        startDate=start;
        endDate=end;
        winnerChoosen=false;

        for (uint i = 0; i < choices.length; i++) {
            proposals.push(Proposal({
                name: choices[i],
                voteCount: 0
            }));
        }
    }

    // 3. A voter can vote for any choices set by the contract owner during the voting period.
    // user use this function to vote for the smart contract, and can select any choices available
    function vote(uint choice) public returns(string memory status) {
        if(block.timestamp>startDate && block.timestamp<endDate){
            Voter storage sender = voters[msg.sender];
            // 4. A voter can only vote once during the voting period.
            // Checking voter status wether they already voted or not
            require(!sender.voted, "Already voted.");
            sender.voted = true;
            sender.vote = choice;
            proposals[choice].voteCount += 1;
            status= "Vote Success";
            users.push(User({
                choice:choice,
                wallet:msg.sender
            }));
        }else{
            require(block.timestamp<startDate && block.timestamp>endDate,"Vote unavailable");
        }
        return status;
    }
    
    // 5. The smart contract can return the number of votes for each choice.
    // returns list of choices
    function getCurrentVoteResults() public view returns( Proposal[] memory ){
        return proposals;
    }

    address[] private winnerListContainer;
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,winnerListContainer)));
    }

     function winningChoice() private view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }
    
    function winningUserArray() private
    {
        uint data = winningChoice();
        for (uint p = 0; p < users.length; p++) {
            if (users[p].choice==data) {
                winnerListContainer.push(users[p].wallet);
            }
        }
    }
    // 8. After the voting period, pick a random voter from the highest voted choice, reward himwith 0.1ETH.
     function chooseLuckyWinner() public payable{
         // Check auth
         require(
            msg.sender == chairperson,
            "Only owner can call this function."
        );
        // Check winner status
         require(winnerChoosen==false,"Winner Already Chosen");
         // Check date
         require(block.timestamp>endDate,"Vote still ongoing");
         winnerChoosen=true;
         winningUserArray();
         uint index=random() % winnerListContainer.length;
         address winner=winnerListContainer[index];
         // 0.1 ETH
         payable(winner).transfer(1000000000);
     }

    // 6. Unit test for the smart contract.
    // Might use jest and web3 nodejs plugin to make the unit test
    // things to test: Date testing, Vote testing, and Reward test

    // 7. Anyone can set up a voting system through the same smart contract.
    // Basically for this smart contract I've only made it to be able to handle 1 vote at a time, for multiple votes, we need an array to contain list of votes and answers and save votes ID for each votes.
    // if there's new votes user need to deploy new smart contract with this codes.
}
