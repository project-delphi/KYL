pragma solidity ^0.4.22;

import './KYLToken.sol';

contract Crowdsale {
    using SafeMath for uint256;       

    // The token being sold
    MintableToken public token;

    // start and end block where investments are allowed (both inclusive)
    uint256 public startBlock;
    uint256 public endBlock;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (uint256 _startBlock, uint256 _endBlock, uint256 _rate, address _wallet) public {
        //require(_startBlock >= block.number, "Actual Block is higher");
        require(_endBlock >= _startBlock, "EB is not higher than SB");
        require(_rate > 0, "Rate must be positive");
        require(_wallet != 0x0, "Funds wallet cannot be 0x0");

        token = createTokenContract();
        startBlock = _startBlock;
        endBlock = _endBlock;
        rate = _rate;
        wallet = _wallet;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() internal returns (MintableToken) {
        return new MintableToken();
    }

    // fallback function can be used to buy tokens
    function () public payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0, "IS ZEOR");
        require(validPurchase(), "INVALID P");

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);
        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        uint256 current = block.number;
        bool withinPeriod = current >= startBlock && current <= endBlock;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return block.number > endBlock;
    }
    
    function CURRENT() public view returns(uint){
        return block.number;
    }
}

contract WhitelistedCrowdsale is Crowdsale, Ownable {
    mapping (address => bool) whitelist;

    function addToWhitelist(address buyer) public onlyOwner {
        require(buyer != 0x0, "Invalid Address");
        whitelist[buyer] = true;
    }

    function isWhitelisted(address buyer) public view returns (bool) {
        return whitelist[buyer];
    }

    function validPurchase() internal view returns (bool) {
        bool isValid = (!hasEnded()) && isWhitelisted(msg.sender);
        return super.validPurchase() || isValid;
    }
}

contract CappedCrowdsale is Crowdsale {
    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }
    
    function validPurchase() internal constant returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= cap;
        return super.validPurchase() && withinCap;
    }

    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= cap;
        return super.hasEnded() || capReached;
    }
}

contract KYLCrowdsale is WhitelistedCrowdsale, CappedCrowdsale{
    //custom rate for each whitelisted buyer
    mapping(address => uint256) buyerRate;
     
    event PreferentialRateChange(address indexed buyer, uint256 rate);
    event InitialRateChange(uint256 rate);
    event EndRateChange(uint256 rate);

    event DEBUG();
    
    uint256 preRate;
    uint256 iniRate;
    uint256 endRate;

    enum phase{pICO, ICO}
    phase public stage;
    
    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _preRate,
        uint256 _iniRate,
        uint256 _endRate,
        address wallet
    )
        public 
        Crowdsale(_startBlock, _endBlock, _iniRate, wallet)
        WhitelistedCrowdsale()
        CappedCrowdsale(100 ether)
    {
        require(_iniRate > 0 && _endRate > 0 && _preRate > 0, "Rate is zero");
        preRate = _preRate;
        iniRate = _iniRate;
        endRate = _endRate;
        stage = phase.pICO;
        
        KYLToken(token).pause();
    }

    /** override */
    function createTokenContract() internal returns (MintableToken) {
        return new KYLToken();
    }

    /** general functions */
    function getRate() public view returns(uint256){
        if (buyerRate[msg.sender] != 0) {
            return buyerRate[msg.sender];
        }

        if (isWhitelisted(msg.sender)) {
            return preRate;
        }

        uint256 elapsed = block.number - startBlock;
        uint256 rateRange = iniRate - endRate;
        uint256 blockRange = endBlock - startBlock;
        return iniRate.sub(rateRange.mul(elapsed).div(blockRange));
    }

    /**PRE ICO: whitelisting */
    /** override */
    function addToWhitelist(address buyer) public onlyOwner {
        require(stage == phase.pICO, "PreICO finished");
        super.addToWhitelist(buyer);
    }
    //CHECK FUNCTIONALITY WITH OWNER
    function setPreferentialRate(address buyer, uint256 rate) public onlyOwner{
        require(stage == phase.pICO, "PreICO finished");
        require(isWhitelisted(buyer), "Address not whitelisted");
        require(rate != 0, "Rate cannot be zero");

        buyerRate[buyer] = rate;
        emit PreferentialRateChange(buyer, rate);
    }
    
    uint256 softCap = 15000000 * (10 ** 18);
    uint256 softRaised;
    
    function mintBonus(address who, uint256 tokens) public onlyOwner{
        require(stage == phase.pICO, "PreICO finished");
        require(isWhitelisted(who), "Address not whitelisted");
        require(softRaised <= softCap); //CHECK WITH OMAR
        
        token.mint(who, tokens);
        softRaised = softRaised.add(tokens);
        
        //emit BonusMinting(who, tokens);
    }

    function finalizepICO() public onlyOwner{
        require(stage == phase.pICO, "PreICO finished");
        require(softRaised == softCap, "Remain tokens");

        stage = phase.pICO;
    }
    
    uint256 hardCap = 50000000 * (10 ** 18);
    uint256 hardRaised;

    /**general access */
    function buyTokens(address who) public payable{
        require(stage != phase.pICO, "Cannot buy tokens in actual phase");
        require(who != 0x0, "Invalid address");
        require(validPurchase(), "Invalid purchase");

        uint256 value = msg.value;
        uint256 rate = getRate();
        uint256 tokens = value.mul(rate);

        weiRaised = weiRaised.add(value);
        softRaised = softRaised.add(value);

        token.mint(who, tokens);
        emit TokenPurchase(msg.sender, who, value, tokens);
        
        forwardFunds();
    }

    function hasEnded() public view returns(bool){
        return super.hasEnded();
    }
    
    /** function finalize(){
        //start airdrops?   
    }*/
}

//envias kyl coins