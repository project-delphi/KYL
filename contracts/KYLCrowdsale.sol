pragma solidity ^0.4.22;

import "./Crowdsale.sol";

contract KYLCrowdsale is CappedCrowdsale{
    uint256 iniRate;
    uint256 endRate;
    
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
        
        token = _token;
    }

    
}