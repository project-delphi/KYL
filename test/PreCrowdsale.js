var KYLToken = artifacts.require('KYLToken');
var KYLCrowdsale = artifacts.require('KYLCrowdsale');

contract('KYLCrowdsale', (accounts) =>{

    const preInvestor = accounts[1];
    const pubInvestor = accounts[2];
    const extInvestor = accounts[3];
    const airDropAddr = accounts[4];

    it('should deploy crowdsale and token contract', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            const token = await ins.token.call();
            assert(token, 'Token address not stored');
            done();
        });
    });

    it('should be preico stage', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            const stage = await ins.stage.call();
            console.log(stage.toNumber(), 0, 'Current stage is not PreICO');
            assert(stage, 'PreICO');
            done();
        });
    });

    it('should be added to whitelist', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            await ins.addToWhitelist(preInvestor);
            const is_in = await ins.isWhitelisted(preInvestor);
            assert.equal(is_in, true, 'Can´t be whitelisted');
            done();
        });
    });

    it('should be able to buy at PreICO', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            await ins.buyTokens(preInvestor, {from: preInvestor, value: web3.toWei(10, 'ether')});
            const token = await ins.token.call();
            const kylToken = KYLToken.at(token);
            const amount = await kylToken.balanceOf(preInvestor);
            assert.equal(amount.toNumber() / (10 ** 18), 16949, 'Cannot buy tokens');
            done();
        });
    });

    it('should match raised wei amount', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            const raised = await ins.weiRaised.call();
            assert.equal(raised.toNumber() / (10 ** 18), 10, 'Wei raised mismatch');
            done();
        });
    });

    it('should be able to mint tokens', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            await ins.mintTo(extInvestor, 25000);
            const token = await ins.token.call();
            const kylToken = KYLToken.at(token);
            const amount = await kylToken.balanceOf(extInvestor);
            assert.equal(Math.ceil(amount.toNumber() / (10 ** 18)), 25000, 'Cannot buy tokens');
            done();
        });
    });

    it('should match raised wei amount', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            const raised = await ins.weiRaised.call();
            assert.equal(raised.toNumber() / (10 ** 18), 24.75, 'Wei raised mismatch');
            done();
        });
    });
     
    it('should be able to airdrop tokens (external buy)', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            await ins.airDrop(airDropAddr, 50000);
            const token = await ins.token.call();
            const kylToken = KYLToken.at(token);
            const amount = await kylToken.balanceOf(airDropAddr);
            assert.equal(Math.ceil(amount.toNumber() / (10 ** 18)), 50000, 'Cannot buy tokens');
            done();
        });
    });

    it('should match airdrop total cap', (done) =>{
        KYLCrowdsale.deployed().then(async (ins) =>{
            const raised = await ins.airDropped;
            assert.equal(raised.toNumber() / (10 ** 18), 50000, 'AirDropped tokens mismatch');
            done();
        });
    });
/*
    it('should match raised wei amount', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            const raised = await ins.weiRaised.call();
            assert.equal(raised.toNumber() / (10 ** 18), 20, 'Wei raised mismatch');
            done();
        });
    });

    it('should match raised airdrops amount', (done) =>{
        KYLPreCrowdsale.deployed().then(async (ins) =>{
            //const raised = await ins.weiRaised.call();
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
*/
});

