pragma solidity ^0.4.22;

import "./Crowdsale.sol";

contract KYLCrowdsale is Ownable, CappedCrowdsale{

    event AirdropSuccess(address indexed who, uint256 tokens);

    enum stage{a, b, c, d}
    stage stages;

    uint256 iniRate;
    uint256 endRate;

    uint256 reserve;
    
    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _iniRate,
        uint256 _endRate,
        address wallet, 
        KYLToken _token
    )
        public
        Crowdsale(_startBlock, _endBlock, _iniRate, wallet)
        CappedCrowdsale(29500 ether)
        /**
         * 590 szabo = 0.25 usd @ 420 usd = 1 ether
         * 590 szabo * 50M KYL = 29500 ether
         */
    {
        require(_iniRate > 0 && _endRate > 0, "Rate is zero");
        iniRate = _iniRate;
        endRate = _endRate;

        reserve = 2250 ether; //590 szabo * 5M KYL = 2250 ether
        token = _token;
    }

    function airDrop(address who, uint rate, uint tokens) public onlyOwner{
        require(who != address(0));
        uint256 value = tokens.mul(rate);
        require(value <= reserve, "Tokens value exceeds reserve");
        
        token.mint(who, tokens * (1 ether));
        emit AirdropSuccess(who, tokens);
    }
}