var KYLPreCrowdsale = artifacts.require('./contracts/KYLPreCrowdsale.sol');

module.exports = function(deployer){
    const startBlock = 10;
    const endBlock = 20000;
    const preRate = 20;
    const fixRate = 25;
    const wallet = "0x352039187ea40cecde81789b8657f09a4f9031f8";
    
    deployer.deploy(KYLPreCrowdsale, startBlock, endBlock, preRate, fixRate, wallet);
}