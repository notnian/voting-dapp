const {expect} = require('chai')
const Voting = artifacts.require("Voting")

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("Voting", function (accounts) {
  const owner = accounts[0]

  beforeEach(async function() {
    this.VotingContract = await Voting.deployed()
  })

  it("should intialize voting status to RegisteringVoters", async function () {
    return assert.equal("RegisteringVoters", await this.VotingContract.getVotingStatus(), "Incorrect voting status")
  })

  it("should register voter", async function () {
    await this.VotingContract.registerVoter(accounts[1])
    await this.VotingContract.registerVoter(accounts[2])
    await this.VotingContract.registerVoter(accounts[3])
    
    const voter1 = await this.VotingContract.voters(accounts[1])
    const voter2 = await this.VotingContract.voters(accounts[2])
    const voter3 = await this.VotingContract.voters(accounts[3])

    expect(voter1.isRegistered && voter2.isRegistered && voter3.isRegistered).to.be.true
  })

  it("should change voting status to ProposalsRegistrationStarted", async function () {
    await this.VotingContract.startProposalRegistration()
    expect(await this.VotingContract.getVotingStatus()).to.be.equal("ProposalsRegistrationStarted")
  })

  it("should register Proposal", async function () {
    const descriptions = ["Prop A", "Prop B", "Prop C"]
    
    // Adding one proposal by added voter
    for (let i = 1; i <= descriptions.length; i++) {
      const description = descriptions[i-1]
      await this.VotingContract.registerProposal(description, {from: accounts[i]})
      const proposal = await this.VotingContract.proposals(i)
      expect(proposal.description).to.be.equal(description)
    }
    
    const proposalCount = await this.VotingContract.getProposalCount()
    expect(proposalCount.toNumber()).to.be.equal(3)
  })

  it("should change voting status to ProposalsRegistrationEnded", async function () {
    await this.VotingContract.stopProposalRegistration()
    expect(await this.VotingContract.getVotingStatus()).to.be.equal("ProposalsRegistrationEnded")
  })

  it("should change voting status to VotingSessionStarted", async function () {
    await this.VotingContract.startVotingSession()
    expect(await this.VotingContract.getVotingStatus()).to.be.equal("VotingSessionStarted")
  })

  it("should vote", async function () {
    await this.VotingContract.vote(2, {from: accounts[1]})
    await this.VotingContract.vote(2, {from: accounts[2]})
    await this.VotingContract.vote(1, {from: accounts[3]})

    const voter1 = await this.VotingContract.voters(accounts[1])
    const voter2 = await this.VotingContract.voters(accounts[2])
    const voter3 = await this.VotingContract.voters(accounts[3])

    expect(voter1.hasVoted && voter1.votedProposalId.toNumber() === 2).to.be.true
    expect(voter2.hasVoted && voter2.votedProposalId.toNumber() === 2).to.be.true
    expect(voter3.hasVoted && voter3.votedProposalId.toNumber() === 1).to.be.true
  })

  it("should change voting status to VotingSessionEnded", async function () {
    await this.VotingContract.stopVotingSession()
    expect(await this.VotingContract.getVotingStatus()).to.be.equal("VotingSessionEnded")
  })

  it("should count votes and change voting status to VotesTallied", async function () {
    await this.VotingContract.countVotes()
    const winner = await this.VotingContract.getWinner()
    
    expect(winner.description).to.equal("Prop B")
    expect(Number(winner.voteCount)).to.equal(2)

    expect(await this.VotingContract.getVotingStatus()).to.be.equal("VotesTallied")

    // Testing last event
    const events = await this.VotingContract.getPastEvents("WorkflowStatusChange")
    expect(events[0].args.previousStatus.toNumber()).to.equal(4)
    expect(events[0].args.newStatus.toNumber()).to.equal(5)
  })
})
