var KYLCrowdsale = artifacts.require('./contracts/KYLCrowdsale.sol');

module.exports = function(deployer){
    const startBlock = 10;
    const endBlock = 20000;
    const iniRate = 590*(10**12);
    const endRate = 590*(10**12);
    const wallet = "0x352039187ea40cecde81789b8657f09a4f9031f8";
    const token = "";
    
    deployer.deploy(KYLPCrowdsale, startBlock, endBlock, iniRate, endRate, wallet, token);
}