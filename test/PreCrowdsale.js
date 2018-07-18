var KYLToken = artifacts.require('KYLToken');
var KYLPreCrowdsale = artifacts.require('KYLPreCrowdsale');

contract('KYLPreCrowdsale', (accounts) =>{
    it('should deploy crowdsale ctr', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            const token = await ins.token.call();
            assert(token, 'Token address not stored');
            done();
        });
    });

    it('should be added to whitelist', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            await ins.addToWhitelist(accounts[1]);
            const isinwl = await ins.isWhitelisted(accounts[1]);
            assert.equal(isinwl, true, 'Can´t be whitelisted');
            done();
        });
    });
    
    it('should set a preferential rate', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            await ins.setPreferentialRate(accounts[1], 590*(10**12));
            const rate = await ins.getRate();
            assert.equal(rate, 590*(10**12), 'Preferential rate unset');
            done();
        });
    });
  
    it('should buy at a preferential rate', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            await ins.buyTokens(accounts[1], {from: accounts[1], value: web3.toWei(10, 'ether')});
            const token = await ins.token.call();
            const kylToken = KYLToken.at(token);
            const amount = await kylToken.balanceOf(accounts[1]);
            assert.equal(amount.toNumber() / (10 ** 18), 16949, 'Cannot buy tokens');
            done();
        });
    });
    
    it('should buy at a normal rate', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            await ins.buyTokens(accounts[2], {from: accounts[2], value: web3.toWei(10, 'ether')});
            const token = await ins.token.call();
            const kylToken = KYLToken.at(token);
            const amount = await kylToken.balanceOf(accounts[2]);
            assert.equal(amount.toNumber() / (10 ** 18), 16949, 'Cannot buy tokens');
            done();
        });
    });

    it('should match raised wei amount', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            const raised = await ins.weiRaised.call();
            assert.equal(raised.toNumber() / (10 ** 18), 20, 'Wei raised mismatch');
            done();
        });
    });

    it('should mint bonus tokens', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            await ins.mintBonus(accounts[1], 14966102);
            const token = await ins.token.call();
            const kylToken = KYLToken.at(token);
            const amount = await kylToken.balanceOf(accounts[1]);
            assert.equal(amount.toNumber() / (10 ** 18), 14983051, 'Can´t mint tokens');
            done();
        });
    });

    it('should match raised wei amount', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            const raised = await ins.weiRaised.call();
            assert.equal(Math.floor(raised.toNumber() / (10 ** 18)), 8850, 'Wei raised mismatch');
            done();
        });
    });
});

