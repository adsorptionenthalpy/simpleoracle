const Contract2 = artifacts.require("Token");
module.exports = function (deployer) {
  deployer.deploy(Contract2, "dust token", "token", 1000000000000);
};
