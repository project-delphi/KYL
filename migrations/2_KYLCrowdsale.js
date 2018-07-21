var KYLCrowdsale = artifacts.require('./contracts/KYLCrowdsale.sol');

module.exports = function(deployer){
    const startBlock = 10;
    const endBlock = 20000;
    const fixRate = 1694;
    const wallet = "0x352039187ea40cecde81789b8657f09a4f9031f8";
    
    deployer.deploy(KYLCrowdsale, startBlock, endBlock, fixRate, wallet);
}