
const Contract = artifacts.require("tokenoracle");
const Contract2 = artifacts.require("token");
var Oracles = ['0xc24ae0a7a92055828c10521e2cae4f06b01026ce',
'0xd7e87c88935fea016a6838f5420fc6b79bd67bf2',
'0x4763ac7610b3cba72522625238701db72b8f5ed1'];
module.exports = function (deployer) {
  deployer.deploy(Contract, Oracles, Contract2.address);
};
