// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./markets/AbstractMarket.sol";
import "./tokens/ReputationToken.sol";
import "./libraries/ContractDeployer.sol";

contract PythiaFactory is ERC721, Ownable {
    using Counters for Counters.Counter;

    event NewMarket(
        address indexed _marketAddress,
        string _question,
        uint256 _wageDeadline,
        uint256 _resolutionDate,
        address _reputationTokenAddress
    );

    event NewUser(
        address indexed _user,
        uint256 _registrationDate
    );

    event NewReputationToken(
        address indexed _address
    );

    event NewReputationTransaction(
        address indexed _user,
        address indexed _market,
        uint256 amount,
        bool received
    );


    // user representation
    struct User{
        uint256 registrationDate;
        bool active;
    }

    //market 
    struct Market{
        bool active;
        address reputationTokenAddress;
    }


    // reputation transaction representation
    struct ReputationTransaction{
        address user;
        address market;
        uint256 amount;
        bool received;
    }
    
    // users
    mapping(address => User) private users;

    //markets
    mapping(address => Market) private markets;

    // reputation token addresses
    mapping(address => bool) reputationTokens;

    // reputation token transactions
    mapping(uint256 => ReputationTransaction) private reputationTransactions;

    // legth of trial period
    uint256 trialPeriod;

    //subcription contract
    ERC948 subscriptionContract;

    Counters.Counter private _tokenIdCounter;

    constructor(
        uint256 _trialPeriodDays,
        address _subscriptionTokenAddress,
        address _treasuryAddress,
        uint256 _baseAmountRecurring
    ) ERC721("PythiaAccount", "PYAC")
    Ownable()
    {
        // trial period in days
        trialPeriod = _trialPeriodDays * 24 * 60 * 60;

        // deploy subsctibtion contract
        subscriptionContract = ERC948(
            ContractDeployer.deploySubscriptionContract(
                _subscriptionTokenAddress,
                _treasuryAddress,
                _baseAmountRecurring
            )
        );
    }

    function createAccount() external  {
        User memory user = User(
            {
                registrationDate: block.timestamp,
                active: true
            }
        );
        users[msg.sender] = user;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        emit NewUser(msg.sender, user.registrationDate);
    }
    
    function isUser(address _user) external view returns(bool){
        return users[_user].active;
    }


    function isInTrial(address _user) external view returns(bool){
        require(block.timestamp >= users[_user].registrationDate, "time is negative");
        uint256 timediff = (
            block.timestamp - users[_user].registrationDate
        );
        return timediff <= trialPeriod;
    }

    function isSubscribed(address _user) external view returns(bool){
        return subscriptionContract.isSubscribed(_user);
    }

    function deployNewReputationToken(
        string memory _name,
        string memory _symbol
    ) external {
        address _tokenAddress = ContractDeployer.deployReputationToken(_name, _symbol);
        reputationTokens[_tokenAddress] = true;
    }

    function createPriceFeedsMarket(
        string memory _question,
        uint256[10] memory _outcomes,
        uint256 _numberOfOutcomes,
        uint256 _wageDeadline,
        uint256 _resolutionDate,
        address _priceFeedAddress,
        address _priceFeederAddress,
        address _reputationTokenAddress
    ) public onlyOwner{
        address _marketAddress = ContractDeployer.deployPriceFeedsMarket(
            address(this),
            _question,
            _outcomes,
            _numberOfOutcomes,
            _wageDeadline,
            _resolutionDate,
            _priceFeedAddress,
            _priceFeederAddress
        );
        markets[_marketAddress].active = true;
        markets[_marketAddress].reputationTokenAddress = _reputationTokenAddress;
        emit NewMarket(
            _marketAddress,
            _question,
            _wageDeadline,
            _resolutionDate,
            _reputationTokenAddress
        );
    }

    function createRealityEthMarket(
        string memory _question,
        uint256 _numberOfOutcomes,
        uint256 _wageDeadline,
        uint256 _resolutionDate,
        uint256 _template_id,
        address _arbitrator,
        uint32 _timeout,
        uint256 _nonce,
        address _realityEthAddress,
        uint256 _min_bond,
        address _reputationTokenAddress
    ) public onlyOwner {
        address _marketAddress = ContractDeployer.deployRealityETHMarket(
            address(this),
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
        );
        markets[_marketAddress].active = true;
        markets[_marketAddress].reputationTokenAddress = _reputationTokenAddress;
        emit NewMarket(
            _marketAddress,
            _question,
            _wageDeadline,
            _resolutionDate,
            _reputationTokenAddress
        );
    }

    function receiveReward(
        address _marketAddress,
        uint256 _decodedPrediction,
        bytes calldata _signature
    ) external {

        uint256 _reputationTransactionHash = uint256(
            keccak256(
                abi.encodePacked(msg.sender, _marketAddress)
            )
        );

        require(
            reputationTransactions[_reputationTransactionHash].received == false,
            "reward was already received"
        );

        AbstractMarket _market = AbstractMarket(_marketAddress);

        uint256 _reward = _market.disclosePrediction(
            _decodedPrediction,
            _signature
        );
    
        address _reputationTokenAddress = _market.getReputationTokenAddress();

        ReputationToken _token = ReputationToken(
            _reputationTokenAddress
        );


        ReputationTransaction memory reputationTransaction = ReputationTransaction(
            {
                user: msg.sender,
                market: _marketAddress,
                amount: _reward,
                received: true
            }
        );

        _token.rate(msg.sender, _reward);
        emit NewReputationTransaction(
            msg.sender,
            _marketAddress,
            _reward,
            true
        );
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
            "user already exists"
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