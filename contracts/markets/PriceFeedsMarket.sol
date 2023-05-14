// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AbstractMarket.sol";
import "../chainlink-contracts/PriceFeeder.sol";




contract PriceFeedsMarket is AbstractMarket{

    uint256[10] outcomes;

    address priceFeedAddress;
    PriceFeeder priceFeeder;

    constructor(
        address _factoryContractAddress,
        string memory _question,
        uint256[10] memory _outcomes,
        uint256 _numberOfOutcomes,
        uint256 _wageDeadline,
        uint256 _resolutionDate,
        address _priceFeedAddress,
        address _priceFeederAddress
    ) AbstractMarket(
        _factoryContractAddress,
        _question,
        _numberOfOutcomes,
        _wageDeadline,
        _resolutionDate
    )
    {
        outcomes = _outcomes;
        priceFeeder = PriceFeeder(_priceFeederAddress);
        priceFeedAddress = _priceFeedAddress;
    }

    function resolve() external override {
        require(
            block.timestamp > resolutionDate,
            "resolution date has not arrived yet"
        );
        answer = _getMarketOutcome();
        resolved = true;
    }

    function _getMarketOutcome() internal view override returns(uint256){
        uint256 price = priceFeeder.getLatestPrice(priceFeedAddress);
        for(uint256 i = 0; i < numberOfOutcomes - 1; i++){
            if(price < outcomes[i]){
                return i;
            }
        }
        return numberOfOutcomes;
    }
}