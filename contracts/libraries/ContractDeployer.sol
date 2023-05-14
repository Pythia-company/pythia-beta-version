pragma solidity ^0.8.0;

import "../markets/PriceFeedsMarket.sol";
import "../markets/RealityETHMarket.sol";
import "../subscription/Subscription.sol";
import "../tokens/ReputationToken.sol";


library ContractDeployer {

    function deployPriceFeedsMarket(
        address _factoryContractAddress,
        string memory _question,
        uint256[10] memory _outcomes,
        uint256 _numberOfOutcomes,
        uint256 _wageDeadline,
        uint256 _resolutionDate,
        address _priceFeedAddress,
        address _priceFeederAddress
    ) external returns(address){
        address _marketAddress = address(
            new PriceFeedsMarket(
                _factoryContractAddress,
                _question,
                _outcomes,
                _numberOfOutcomes,
                _wageDeadline,
                _resolutionDate,
                _priceFeedAddress,
                _priceFeederAddress
            )
        );
        return _marketAddress;
    }

    function deployRealityETHMarket(
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
    ) external returns(address){
        address _marketAddress = address(
            new RealityETHMarket(
                _factoryContractAddress,
                _question,
                _numberOfOutcomes,
                _wageDeadline,
                _resolutionDate,
                _template_id,
                _arbitrator,
                _timeout,
                _nonce,
                _realityEthAddress,
                _min_bond
            )
        );
        return _marketAddress;
    }

    function deploySubscriptionContract(
        address _subscriptionTokenAddress,
        address _payeeAddress,
        uint256 _baseAmountRecurring
    ) external returns(address){
        address _subscriptionContractAddress = address(
            new ERC948(
                _subscriptionTokenAddress,
                _payeeAddress,
                _baseAmountRecurring
            )
        );
        return _subscriptionContractAddress;
    }

    function deployReputationToken(
        string memory _name, 
        string memory _symbol
    ) external returns(address){
        address _reputationTokenAddress = address(
            new ReputationToken(_name, _symbol)
        );
        return _reputationTokenAddress;
    }
}