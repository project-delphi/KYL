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
        require(_endBlock >= _startBlock);
        require(_rate > 0);
        require(_wallet != 0x0);

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
        require(beneficiary != 0x0);
        require(validPurchase());

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
}

contract WhitelistedCrowdsale is Crowdsale, Ownable {
    mapping (address => bool) whitelist;

    function addToWhitelist(address buyer) public onlyOwner {
        require(buyer != 0x0);
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