pragma solidity ^0.4.22;

import "./Crowdsale.sol";

contract KYLCrowdsale is Pausable, WhitelistedCrowdsale, CappedCrowdsale{
    enum stages {pICO, ICO, end}

    event PreCrowdsaleStarted();
    event CrowdsaleStarted();
    event RateChanged(uint256 rate);

    event ExternalPurchase(address indexed who, uint256 tokens);
    event AirDroppedTokens(address indexed who, uint256 tokens);

    stages public stage;

    uint256 airdropCap;
    uint256 airDropped;

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _fixRate,
        uint256 _airdropCap,
        address wallet
    )
        public 
        Crowdsale(_startBlock, _endBlock, _fixRate, wallet)
        WhitelistedCrowdsale()
        CappedCrowdsale(8850 ether) 
        /**
         * RATE FOR 0.25 USD = 590 * 10**12 Wei
         * 590 szabo = 0.25 usd @ 420 usd = 1 ether
         * 590 szabo * 15M KYL = 8850 ether
         */
    {
        stage = stages.pICO;
        airdropCap = _airdropCap;
        KYLToken(token).pause();

        emit PreCrowdsaleStarted();
    }

    /** function override */
    function createTokenContract() internal returns (MintableToken) {
        return new KYLToken();
    }

    function setRate(uint256 _rate) public whenPaused onlyOwner{
        require(_rate > 0, "Rate is zero");
        rate = _rate * (1 ether);
        emit RateChanged(rate);
    }

    function getRate() public view returns(uint256){
        return rate;
    }

    /**function override */
    function buyTokens(address who) public whenNotPaused payable{
        require(who != 0x0, "Invalid address");
        require(super.validPurchase(), "Invalid purchase");

        if(stage == stages.pICO){
            require(super.isWhitelisted(who), "Address not whitelisted");
        }
        
        uint256 value = msg.value;
        uint256 tokens = value.div(rate) * 1 ether;
        weiRaised = weiRaised.add(value);

        token.mint(who, tokens);
        emit TokenPurchase(msg.sender, who, value, tokens);
        
        super.forwardFunds();
    }

    /* handle external buyers */
    function mintTo(address who, uint256 tokens) public onlyOwner{
        require(who != 0x0, "Invalid address");
        uint256 value = tokens.mul(rate);
        require(value <= cap, "Tokens value exceeds cap");
        weiRaised = weiRaised.add(value);
        
        token.mint(who, tokens * (1 ether));
        emit ExternalPurchase(who, tokens);
    }

    /* airdrop tokens */
    function airDrop(address who, uint256 tokens) public onlyOwner{
        require(who != 0x0, "Invalid address");
        require(tokens > 0, "Invalid token amount");
        
        airDropped = airDropped.add(tokens);
        require(airDropped <= airdropCap);

        //should be in KYL?
        token.mint(who, tokens * (1 ether));
        emit AirDroppedTokens(who, tokens);
    }

    // finalize pICO, goto next stage
    function nextStage() public onlyOwner whenPaused{
        require(stage == stages.pICO);
        stage = stages.ICO;

        emit CrowdsaleStarted();
    }

    //finalize public crowdsale
    function finalize() public onlyOwner whenPaused{
        stage = stages.end;
        KYLToken(token).unpause();
    }

    /* liberate foundation tokens */
    function liberate(uint256 tokens) public onlyOwner{
        require(stage == stages.end);
        token.mint(wallet, tokens);
    }
  
    /**fallback function override */
    function () public payable {
        buyTokens(msg.sender);
    }

}