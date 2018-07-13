pragma solidity ^0.4.22;

import "./Crowdsale.sol";

contract KYLPreCrowdsale is WhitelistedCrowdsale, CappedCrowdsale{
    //custom rate for each whitelisted buyer
    mapping(address => uint256) buyerRate;

    event FixedRateChanged(uint256 rate);
    event PreferentialRateChange(address indexed buyer, uint256 rate);
    event BonusMintedTokens(address indexed who, uint256 tokens);

    uint256 preRate;
    uint256 fixRate;

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _preRate,
        uint256 _fixRate,
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
        require(_preRate > 0 && _fixRate > 0, "Rate is zero");
        preRate = _preRate;
        fixRate = _fixRate;
        
        KYLToken(token).pause();
    }

    /** function override */
    function createTokenContract() internal returns (MintableToken) {
        return new KYLToken();
    }

    function getRate() public view returns(uint256){
        if (super.isWhitelisted(msg.sender)) {
            if (buyerRate[msg.sender] == 0){
                return preRate;
            }else{
                return buyerRate[msg.sender];
            }
        }

        return fixRate;
    }

    function setPreferentialRate(address buyer, uint256 rate) public onlyOwner{
        require(super.isWhitelisted(buyer), "Address not whitelisted");
        require(rate != 0, "Rate cannot be zero");

        buyerRate[buyer] = rate;
        emit PreferentialRateChange(buyer, rate);
    }

    function mintBonus(address who, uint256 tokens) public onlyOwner{
        require(super.isWhitelisted(who), "Address not whitelisted");
        uint256 value = tokens.mul(buyerRate[who]);
        require(value <= cap, "Tokens value exceeds cap");

        weiRaised = weiRaised.add(value);
        
        token.mint(who, tokens * (1 ether));
        emit BonusMintedTokens(who, tokens);
    }

    /**function override */
    function buyTokens(address who) public payable{
        require(who != 0x0, "Invalid address");
        require(super.validPurchase(), "Invalid purchase");

        uint256 value = msg.value;
        //uint256 rate = getRate();
        uint256 tokens = value.div(getRate()) * 1 ether;

        weiRaised = weiRaised.add(value);

        token.mint(who, tokens);
        emit TokenPurchase(msg.sender, who, value, tokens);
        
        super.forwardFunds();
    }
    
    /**function override */
    function () public payable {
        buyTokens(msg.sender);
    }
}