const{expect} = require("chai");
const{expectRevert, ether} = require("@openzeppelin/test-helpers");


describe("Testing Multisig Wallet", function(){


    let owner, owner1, owner2, owner3, owner4, owner5, account1, Contract, contract;


    before(async()=>{


        [owner, owner1, owner2, owner3, owner4, owner5, account1] = await ethers.getSigners();

        Contract = await ethers.getContractFactory("MultiSig");
        contract = await Contract.deploy(
            [
                "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
                "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
                "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
                "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
                "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
        ], 3);
        await contract.deployed();
    });


    it("owners should be able to deposit some ether", async()=>{
        await contract.connect(owner).deposit({value: "1000000000000000000"});
        await contract.connect(owner1).deposit({value: "1000000000000000000"});
        await contract.connect(owner2).deposit({value: "1000000000000000000"});
        await contract.connect(owner3).deposit({value: "1000000000000000000"});
        await contract.connect(owner4).deposit({value: "1000000000000000000"});
        let balances = await contract.contractBalance();
        console.log("Contract Balance after deposit", balances.toString(), "ether");
    });



    it("should be able to make proposal if you are one of the owners", async()=>{
        await contract.connect(owner).submitProposal(account1.address, "1000000000000000000");
        let txDetails = await contract.transactionIdDetails(1);
        console.log(txDetails);

    });



    it("should revert to make proposal if you are NOT one of the owners", async()=>{
        await expectRevert(contract.connect(account1).submitProposal(owner.address, "1000000000000000000"),
            "No one of owners");
    });


    it("should revert setting new confirmation for the proposal if you are the proposer", async()=>{
        await expectRevert(contract.connect(owner).confirmProposalId(1), "Already Vote for this proposal!");
    });



    it("should be able to set a new confirmation for the transaction", async()=>{
        await contract.connect(owner1).confirmProposalId(1);
        let proposalStatus = await contract.transactionIdDetails(1);
        let proposalConfirmations = proposalStatus.confirmations;
        console.log("Confirmations Amount: ", proposalConfirmations.toString());

    });



    it("should be able to revoke confirmations for a proposal", async()=>{
        await contract.connect(owner1).revokeProposalId(1);
        let proposalStatus = await contract.transactionIdDetails(1);
        let proposalConfirmations = proposalStatus.confirmations;
        console.log("Confirmations Amount: ", proposalConfirmations.toString());
    });



    it("should revert to execute proposal if there are not necessary amount of confirmations", async()=>{
        await expectRevert(contract.connect(owner).executeProposalId(1), "Not necessary amount of confirmations");
    });


    it("should execute proposal id if the min amount of confirmations is reached", async()=>{
        await contract.connect(owner1).confirmProposalId(1);
        await contract.connect(owner2).confirmProposalId(1);

        await contract.connect(owner).executeProposalId(1);

        let contractBalance = await contract.contractBalance();
        console.log(contractBalance.toString());
        let toBalance = await ethers.provider.getBalance(account1.address);
        console.log(toBalance.toString());
    });








})