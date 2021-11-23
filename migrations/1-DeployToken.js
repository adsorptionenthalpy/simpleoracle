const Contract2 = artifacts.require("token");
module.exports = function (deployer) {
  deployer.deploy(Contract2, "dust token", "token", 1000000000000);
};
