// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './AbstractMarket.sol';
import '../reality-eth/RealityETH.sol';



contract RealityETHMarket is AbstractMarket{
    uint32 timeout;
    uint256 nonce;
    uint256 min_bond;
    address arbitrator;
    RealityETH_v3_0 realityETH;
    bytes32 realityETHQuestionId;
    uint256 template_id;

    constructor(
        address _factoryContractAddress,
        string memory _question,
        uint256 _numberOfOutcomes,
        uint256 _wageDeadline,
        uint256 _resolutionDate,
        uint256 _template_id,
        address _arbitrator,
        uint32 _timeout,
        uint256 _nonce,
        address _realityEthAddress,
        uint256 _min_bond
    ) AbstractMarket(
        _factoryContractAddress,
        _question,
        _numberOfOutcomes,
        _wageDeadline,
        _resolutionDate
    )
    { 
        template_id = _template_id;
        arbitrator = _arbitrator;
        timeout = _timeout;
        realityETH = RealityETH_v3_0(_realityEthAddress);
        min_bond = _min_bond;
        nonce = _nonce;

        realityETHQuestionId = realityETH.askQuestionWithMinBond(
            template_id,
            question,
            arbitrator,
            timeout,
            uint32(resolutionDate),
            nonce,
            min_bond
        );
    }

    function resolve() external override{
        require(
            block.timestamp > resolutionDate,
            "resolution date has not arrived yet"
        );
        answer =  _getMarketOutcome();
        resolved = true;
    }

    function _getMarketOutcome() internal view override returns(uint256){
        return uint256(realityETH.resultFor(realityETHQuestionId));
    }
}