//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/utils/Counters.sol";

pragma solidity ^0.8.4;


contract MultiSig{
    using Counters for Counters.Counter;
    Counters.Counter private _txId;


    address[] public owners;
    uint public confirmationsNumber;


    struct Transaction{
        address to;
        uint amount;
        uint confirmations;
        bool executed;
    }

    mapping(uint=>Transaction)public transactionIdDetails;
    mapping(address=>bool)public isOwner;
    mapping(address=>mapping(uint => bool))public voter;


    modifier onlyOwner(){
        require(isOwner[msg.sender], "No one of owners");
        _;
    }


    event createdProposal(uint txId, address _to, uint _amount, uint _confirmationsAmount, bool _executed);
    event confirmProposal(uint txId, address signer);
    event revokeProposal(uint txId, address signer);
    event executeProposal(uint txId, address _to, uint _amount, uint _confirmationsAmount, bool _executed);




    constructor(address[] memory _owners, uint confirmNecessaryAmount){
        require(
            _owners.length > 0 && 
            confirmNecessaryAmount <= _owners.length
            );
        
        for(uint i = 0; i < _owners.length; ++i){
            address owner = _owners[i];
            require(owner != address(0), "0 Address can't be setted as owner!");
            require(isOwner[owner] == false, "Owner already Setted!");

            isOwner[owner] = true;
            owners.push(owner);
        }
        confirmationsNumber = confirmNecessaryAmount;
    }



    function deposit()external payable onlyOwner{
        require(msg.value > 0, "Can't deposit 0 ether!");
    }



    function submitProposal(address to, uint amount)public onlyOwner{
        _txId.increment();
        uint newTxId = _txId.current();
        transactionIdDetails[newTxId].amount = amount;
        transactionIdDetails[newTxId].to = to;
        transactionIdDetails[newTxId].confirmations = 1;
        transactionIdDetails[newTxId].executed = false;
        voter[msg.sender][newTxId] = true;
    }



    function confirmProposalId(uint txId)public onlyOwner{
        require(voter[msg.sender][txId] == false, "Already Vote for this proposal!");
        uint provvisoryConfirmations =  transactionIdDetails[txId].confirmations;
        require(provvisoryConfirmations < confirmationsNumber, "Confirmations already reached!");
        transactionIdDetails[txId].confirmations += 1;
        voter[msg.sender][txId] = true;
    }



    function revokeProposalId(uint txId)public onlyOwner{
        require(voter[msg.sender][txId] == true, "You didn't vote to confirm proposal");
        uint provvisoryConfirmations =  transactionIdDetails[txId].confirmations;
        require(provvisoryConfirmations < confirmationsNumber, "Confirmations already reached!");
        transactionIdDetails[txId].confirmations -= 1;
        voter[msg.sender][txId] = false;
    }



    function executeProposalId(uint txId)public onlyOwner{
        uint provvisoryConfirmations =  transactionIdDetails[txId].confirmations;
        bool proposalStatus = transactionIdDetails[txId].executed;
        require(provvisoryConfirmations >= confirmationsNumber, "Not necessary amount of confirmations");
        require(proposalStatus == false, "Already executed proposal!");
        address _to = transactionIdDetails[txId].to;
        uint amountToSend = transactionIdDetails[txId].amount;
        payable(_to).transfer(amountToSend);
        transactionIdDetails[txId].executed = true;

    }


    function contractBalance()public view returns(uint){
        return address(this).balance;
    }



    receive()external payable{}
}