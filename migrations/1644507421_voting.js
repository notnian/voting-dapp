const Voting = artifacts.require("./Voting.sol");

module.exports = function(_deployer) {
  // Use deployer to state migration tasks.
  _deployer.deploy(Voting);
};
