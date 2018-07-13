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
        CappedCrowdsale(8840 ether) // = 15,000,000 KYL @ 0.25usd c/u @420 usd = 1 ether
    {
        require(_iniRate > 0 && _endRate > 0, "Rate is zero");
        iniRate = _iniRate;
        endRate = _endRate;
        
        token = _token;
    }
}