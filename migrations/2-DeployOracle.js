
const Contract = artifacts.require("Tokenoracle");
const Contract2 = artifacts.require("Token");
var Oracles = ['0x18C44d52023E955675d84AC602324b66feae81f2',
'0x87258d0028a84987Cdf278Ee3A5888be4E486026',
'0xe7edF1080BF2593E78c4D91b3E58CDc4Db502010'];
module.exports = function (deployer) {
  deployer.deploy(Contract, Oracles, Contract2.address);
};
