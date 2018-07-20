pragma solidity ^0.4.22;

import "./Crowdsale.sol";

contract KYLCrowdsale is Pausable, WhitelistedCrowdsale, CappedCrowdsale{
    enum stages {pICO, ICO, end}

    event PreCrowdsaleStarted();
    event CrowdsaleStarted();
    event CrowdsaleFinished();
    event RateChanged(uint256 rate);

    event ExternalPurchase(address indexed who, uint256 tokens);
    event AirDroppedTokens(address indexed who, uint256 tokens);

    stages public stage;

    uint256 public softCap;
    uint256 public hardCap;

    uint256 public airdropCap;
    uint256 public airDropped;

    uint256 public founderCap;
    uint256 public teamMinted;

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _fixRate,
        uint256 _airdropCap,
        uint256 _founderCap,
        address wallet
    )
        public 
        Crowdsale(_startBlock, _endBlock, _fixRate, wallet)
        WhitelistedCrowdsale()
        CappedCrowdsale(38350 ether) 
        /**
         * RATE FOR 0.25 USD = 590 * 10**12 Wei
         * 590 szabo = 0.25 usd @ 420 usd = 1 ether
         * 590 szabo * 15M KYL = 8850 ether
         */
    {
        stage = stages.pICO;

        softCap = 8850 ether;
        hardCap = 29500 ether;

        airdropCap = _airdropCap;
        founderCap = _founderCap;

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

    /**function override */
    function buyTokens(address who) public whenNotPaused payable{
        require(who != 0x0, "Invalid address");
        require(super.validPurchase(), "Invalid purchase");

        if(stage == stages.pICO){
            require(super.isWhitelisted(who), "Address not whitelisted");
            require(weiRaised <= softCap, "Value exceeds softcap");
        }
        
        uint256 value = msg.value;
        uint256 tokens = value.mul(rate);
        weiRaised = weiRaised.add(value);

        token.mint(who, tokens);
        emit TokenPurchase(msg.sender, who, value, tokens);
        
        super.forwardFunds();
    }

    /* handle external buyers */
    function mintTo(address who, uint256 tokens) public onlyOwner{
        require(who != 0x0, "Invalid address");
        require(tokens > 0, "Invalid token amount");

        if(stage == stages.pICO){
            require(weiRaised <= softCap);
        }

        uint256 total = tokens.mul(1 ether);
        uint256 value = total.div(rate);
        require(value <= cap, "Tokens value exceeds cap");

        weiRaised = weiRaised.add(value);
        
        token.mint(who, total);
        emit ExternalPurchase(who, total);
    }

    /* airdrop tokens */
    function airDrop(address who, uint256 tokens) public onlyOwner{
        require(who != 0x0, "Invalid address");
        require(tokens > 0, "Invalid token amount");
        require(airDropped.add(tokens) <= airdropCap);

        airDropped = airDropped.add(tokens);

        token.mint(who, tokens.mul(1 ether));
        emit AirDroppedTokens(who, tokens);
    }

    // finalize pICO, goto next stage
    function endPreICO(uint256 _rate) public onlyOwner whenPaused{
        require(stage == stages.pICO, "Current stage is not preICO");
        stage = stages.ICO;
        rate = _rate;

        super.unpause();
        emit CrowdsaleStarted();
    }

    //finalize public crowdsale
    function finalize() public onlyOwner whenPaused{
        require(block.number >= endBlock);
        stage = stages.end;
        
        uint256 left = cap.sub(weiRaised).mul(rate);
        token.mint(0x0, left);

        KYLToken(token).unpause();
        emit CrowdsaleFinished();
    }

    /* partially liberate foundation tokens */
    function teamMint(uint256 tokens) public onlyOwner{
        require(tokens > 0, "Invalid token amount");
        require(teamMinted.add(tokens) <= founderCap, "Amount exceeds");
        require(stage == stages.end, "Wrong stage");

        founderCap = founderCap.add(tokens);

        token.mint(wallet, tokens);
    }

}