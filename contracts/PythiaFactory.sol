// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./markets/AbstractMarket.sol";
import "./markets/PriceFeedsMarket.sol";
import "./markets/RelityEthMarket.sol";
import "./tokens/ReputationToken.sol";
import "./subscription/Subscription.sol";

contract PythiaFactory is ERC721, ERC721Burnable, Ownable, ERC948 {
    using Counters for Counters.Counter;

    struct User{
        uint256 registrationDate;
        bool active;
    }

    struct ReputationTransaction{
        address reputationTokenAddress;
        uint256 amount;
    }
    
    address[] marketAddresses;
    mapping(address => User) private users;
    mapping(address => bool) private markets;
    mapping(uint256 => ReputationTransaction) private reputationTransactions;

    uint256 trialPeriod;
    Subscription subscriptionContract;

    Counters.Counter private _tokenIdCounter;

    constructor(
        uint256 _trialPeriodDays,
        address _subscriptionTokenAddress
    ) ERC721("PythiaAccount", "PYAC")
    Ownable()
    ERC948(_subscriptionTokenAddress){
        require(_trialPeriodDays < 60, "trial period exceeds sensible number");
        trialPeriod = _trialPeriodDays * 24 * 60 * 60;

    }

    function createAccount() external  {
        require(
            users[msg.sender].active == false,
            "account already exists"
        );
        users[msg.sender].registrationDate = block.timestamp;
        users[msg.sender].active = true;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function createSubscription(
        address _payeeAddress,
        uint _amountRecurring,
        uint _amountInitial,
        uint _periodType,
        uint _periodMultiplier,
        uint _startTime,
        string calldata _data
        )
        external
        override
        subscriptionNotActive
    {
        require(
            users[msg.sender].active == true,
            "user account does not exist"
        );
        // Ensure that _periodType is valid
        // TODO support hour, day, week, month, year
        require(
            (_periodType == 0),
            'Only period types of second are supported'
        );

        // Check that subscription start time is now or in the future
        require((_startTime >= block.timestamp),
                'Subscription must not start in the past');

        uint amountRequired = _amountInitial + _amountRecurring;
        require((subscriptionToken.balanceOf(msg.sender) >= amountRequired),
                'Insufficient balance for initial + 1x recurring amount');

        //  Check that contact has approval for at least the initial and first recurring payment
        require(
            subscriptionToken.allowance(
                msg.sender,
                address(this)
            ) >= amountRequired,
            'Insufficient approval for initial + 1x recurring amount'
        );

        Subscription memory newSubscription = Subscription({
            payeeAddress: _payeeAddress,
            amountRecurring: _amountRecurring,
            amountInitial: _amountInitial,
            periodType: _periodType,
            periodMultiplier: _periodMultiplier,

            // TODO set start time appropriately and deal with interaction w nextPaymentTime
            startTime: block.timestamp,

            data: _data,
            active: true,

            // TODO support hour, day, week, month, year
            nextPaymentTime: block.timestamp + _periodMultiplier
        });
        subscriptions[msg.sender] = newSubscription;
    }

    function isTrialUser(address _userAddress) external view returns(bool){
        require(
            users[_userAddress].active == true,
            "account does not exist"
        );
        uint256 timediff = (
            block.timestamp - users[_userAddress].registrationDate
        );
        return timediff > trialPeriod;
    }

    function createPriceFeedsMarket(
        string memory _question,
        uint256[10] memory _outcomes,
        uint256 _numberOfOutcomes,
        uint256 _wageDeadline,
        uint256 _resolutionDate,
        address _reputationTokenAddress,
        address _priceFeedAddress,
        address _priceFeederAddress
    ) public onlyOwner returns(address){
        PriceFeedsMarket _marketAddress = new PriceFeedsMarket(
            _question,
            _outcomes,
            _numberOfOutcomes,
            _wageDeadline,
            _resolutionDate,
            _reputationTokenAddress,
            _priceFeedAddress,
            _priceFeederAddress
        );
        marketAddresses.push(address(_marketAddress));
        markets[address(_marketAddress)] = true;
        return address(_marketAddress);
    }

    function createRealityEthMarket(
        uint256 _wageDeadline,
        uint256 _resolutionDate,
        uint256 _numberOfOutcomes,
        address _reputationTokenAddress,
        string memory _question,
        uint256 _template_id,
        address _arbitrator,
        uint32 _timeout,
        uint256 _nonce,
        address _realityEthAddress,
        uint256 _min_bond
    ) public onlyOwner returns(address){
        RealityETHMarket _marketAddress = new RealityETHMarket(
            _question,
            _numberOfOutcomes,
            _wageDeadline,
            _resolutionDate,
            _reputationTokenAddress,
            _template_id,
            _arbitrator,
            _timeout,
            _nonce,
            _realityEthAddress,
            _min_bond
        );
        marketAddresses.push(address(_marketAddress));
        markets[address(_marketAddress)] = true;
        return address(_marketAddress);
    }

    function receiveReward(
        address _marketAddress,
        uint256 _decodedPrediction,
        bytes calldata _signature
    ) public {
        AbstractMarket _market = AbstractMarket(_marketAddress);
        uint256 _reward;
        _reward = _market.disclosePrediction(
            _decodedPrediction,
            _signature
        );
        address _reputationTokenAddress = _market.getReputationTokenAddress();
        ReputationToken _token = ReputationToken(
            _reputationTokenAddress
        );
        uint256 _reputationTransactionHash = uint256(
            keccak256(
                abi.encodePacked(msg.sender, _marketAddress)
            )
        );
        (
            reputationTransactions
            [_reputationTransactionHash]
            .reputationTokenAddress
        ) = _reputationTokenAddress;
        (
            reputationTransactions
            [_reputationTransactionHash]
            .amount
        ) = _reward;
        _token.rate(msg.sender, _reward);
    }

    function updateTrialPeriod(uint256 _newtrialPeriod) public onlyOwner{
        trialPeriod =  _newtrialPeriod;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        require(
            users[to].active == false,
            "account already exists"
        );
        require(
            from == address(0) || to == address(0),
            "can't transfer profile"
        );
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        emit Transfer(to, from, firstTokenId);
    }

}