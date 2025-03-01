// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './AbstractMarket.sol';

contract TestMarket is AbstractMarket{

    constructor(
        string memory _question,
        uint256 _numberOfOutcomes,
        uint256 _wageDeadline,
        uint256 _resolutionDate
    ) AbstractMarket(
        _question,
        _numberOfOutcomes,
        _wageDeadline,
        _resolutionDate
    ){}

    function resolve() external override returns(bool){
        answer = _getMarketOutcome();
        return true;
    }

    function _getMarketOutcome() public override view returns(uint256){
        return 0;
    }

}