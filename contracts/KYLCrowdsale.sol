pragma solidity ^0.4.22;

import "./Crowdsale.sol";

contract KYLCrowdsale is Pausable, WhitelistedCrowdsale, CappedCrowdsale{
    enum stages {pICO, ICO}

    event PreCrowdsaleStarted();
    event CrowdsaleStarted();
    event CrowdsaleFinished();
    event RateChanged(uint256 rate);

    event ExternalPurchase(address indexed who, uint256 tokens);
    event AirDroppedTokens(address indexed who, uint256 tokens);
    event TeamMintedTokens(uint256 tokens);

    stages public stage;

    uint256 public softCap;
    uint256 public hardCap;
    uint256 public teamCap;
    uint256 public airdropCap;

    constructor(
        uint256 _startBlock, uint256 _endBlock, 
        uint256 _fixRate, address wallet
    )
        public 
        Crowdsale(_startBlock, _endBlock, _fixRate, wallet)
        WhitelistedCrowdsale()
        CappedCrowdsale(38350 ether)
    {
        stage = stages.pICO;

        softCap = 15000000;
        hardCap = 50000000;
        teamCap = 30000000;
        airdropCap = 5000000;

        KYLToken(token).pause();

        emit PreCrowdsaleStarted();
    }

    /** function override */
    function createTokenContract() internal returns (MintableToken) {
        return new KYLToken();
    }

    function setRate(uint256 _rate) public whenPaused onlyOwner{
        require(_rate > 0, "Rate is zero");
        rate = _rate;
        emit RateChanged(rate);
    }

    /** function override */
    function buyTokens(address who) public whenNotPaused payable{
        require(who != 0x0, "Invalid address");
        require(super.validPurchase(), "Invalid purchase");

        uint256 value = msg.value;
        uint256 tokens = value.mul(rate);

        if(stage == stages.pICO){
            require(super.isWhitelisted(who), "Address not whitelisted");
            require(softCap.sub(tokens.div(1 ether)) >= 0, "Tokens exceed softcap");        
            softCap = softCap.sub(tokens.div(1 ether));
        }else if(stage == stages.ICO){
            require(hardCap.sub(tokens.div(1 ether)) >= 0, "Tokens exceed hardcap");
            hardCap = hardCap.sub(tokens.div(1 ether));
        }
        
        weiRaised = weiRaised.add(value);
        token.mint(who, tokens);
        emit TokenPurchase(msg.sender, who, value, tokens);
        
        super.forwardFunds();
    }

    /* handle external buyers */
    function mintTo(address who, uint256 tokens) public onlyOwner{
        require(who != 0x0, "Invalid address");
        require(tokens > 0, "Invalid token amount");

        uint256 total = tokens.mul(1 ether);
        uint256 value = total.div(rate);

        if(stage == stages.pICO){
            require(softCap.sub(tokens) >= 0, "Tokens exceed softcap");
            softCap = softCap.sub(tokens);
        }else if(stage == stages.ICO){
            require(hardCap.sub(tokens) >= 0, "Tokens exceed hardcap");
            hardCap = hardCap.sub(tokens);
        }

        weiRaised = weiRaised.add(value);
        token.mint(who, total);
        emit ExternalPurchase(who, total);
    }

    /* airdrop tokens */
    function airDrop(address who, uint256 tokens) public onlyOwner{
        require(who != 0x0, "Invalid address");
        require(tokens > 0, "Invalid token amount");
        require(airdropCap.sub(tokens) >= 0, "Amount exceeds airdrop cap");

        airdropCap = airdropCap.sub(tokens);

        token.mint(who, tokens.mul(1 ether));
        emit AirDroppedTokens(who, tokens);
    }

    /* finalize pICO, goto next stage */
    function endPreICO(uint256 _rate) public onlyOwner whenPaused{
        require(stage == stages.pICO, "Current stage is not preICO");
        stage = stages.ICO;
        rate = _rate;

        super.unpause();
        emit CrowdsaleStarted();
    }

    /* finalize public crowdsale */
    function finalize() public onlyOwner whenPaused{
        require(block.number >= endBlock, "EndBlock not reached yet");
        
        uint256 left = cap.sub(weiRaised).mul(rate);
        token.mint(0x0, left);

        KYLToken(token).unpause();
        emit CrowdsaleFinished();
    }

    /* partial liberate foundation tokens */
    function teamMint(uint256 tokens) public onlyOwner{
        require(tokens > 0, "Token amount cannot be 0");
        require(teamCap.sub(tokens) >= 0, "Token amount exceeds team cap");
        require(hasEnded(), "Crowdsale has not finished");

        teamCap = teamCap.sub(tokens);
        token.mint(wallet, tokens);

        emit TeamMintedTokens(tokens);
    }
}