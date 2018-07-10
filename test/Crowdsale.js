var KYLToken = artifacts.require('KYLToken');
var KYLCrowdsale = artifacts.require('KYLCrowdsale');

contract('KYLCrowdsale', (accounts) =>{
    it('should deploy crowdsale ctr', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            const token = await ins.token.call();
            assert(token, 'Token address not stored');
            done();
        });
    });

    it('should be added to whitelist', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            await ins.addToWhitelist(accounts[1]);
            const isinwl = await ins.isWhitelisted(accounts[1]);
            assert.equal(isinwl, true, 'Can´t be whitelisted');
            done();
        });
    });

    it('should buy at a preferential rate', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            await ins.setPreferentialRate(accounts[1], 15);
            await ins.buyTokens(accounts[1], {from: accounts[1], value: web3.toWei(10, 'ether')});
            const token = await ins.token.call();
            const kylToken = KYLToken.at(token);
            const amount = await kylToken.balanceOf(accounts[1]);
            assert.equal(amount.toNumber() / (10 ** 18), 150, 'Rate assignment failed');
            done();
        });
    });

});