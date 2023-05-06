// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../libraries/SignatureVerifier.sol';
import "../libraries/Maths.sol";
import "../PythiaFactory.sol";


abstract contract AbstractMarket{


    uint256 constant MULTIPLIER = 10**10;
    uint256 constant LNDENOMINATION = 5;

    PythiaFactory pythiaFactory;

    struct Prediction{
        uint256 predictionTimestamp;
        bytes32 encodedPrediction;
        uint256 decodedPrediction;
        bool predicted;
        bool correct;
        bool verifiedPrediction;
    }
    string question;
    uint256 numberOfOutcomes;
    uint256 creationDate;
    uint256 wageDeadline;
    uint256 resolutionDate;
    address reputationTokenAddress;
    bool resolved;
    uint256 answer;
    uint256 marketId;
    
    mapping(address => Prediction) public predictions;

    constructor(
        string memory _question,
        uint256 _numberOfOutcomes,
        uint256 _wageDeadline,
        uint256 _resolutionDate,
        address _reputationTokenAddress
    ){  
        pythiaFactory = PythiaFactory(msg.sender);
        creationDate = block.timestamp;
        marketId = _generateMarketId(_question);
        question = _question;
        wageDeadline = _wageDeadline;
        resolutionDate = _resolutionDate;
        reputationTokenAddress = _reputationTokenAddress;
        numberOfOutcomes = _numberOfOutcomes;
        resolved = false;
    }

    function predict(bytes32 _encodedPrediction) external virtual {
        require(
            block.timestamp <= wageDeadline,
            "market is not active"
        );
        require(
            (
                (pythiaFactory.isSubscribed(msg.sender) == true) ||
                (pythiaFactory.isTrialUser(msg.sender) == true)
            ),
            "user is not in trial or not subscribed"
        );
        predictions[msg.sender].encodedPrediction = _encodedPrediction;
        predictions[msg.sender].predictionTimestamp = block.timestamp;
        predictions[msg.sender].predicted = true;
    }

    function disclosePrediction(
        uint256 _decodedPrediction,
        bytes calldata _signature
    ) external virtual returns(uint256){
        require(resolved == true, "market has not yet resolved");
        require(
            predictions[msg.sender].predicted == true,
            "user has not predicted"
        );
        bool verified = _verifyPrediction(
            predictions[msg.sender].encodedPrediction,
            _decodedPrediction,
            _signature
        );
        if(verified ==  true){
            predictions[msg.sender].verifiedPrediction = true;
            bool correct = answer == _decodedPrediction;
            predictions[msg.sender].correct = correct;
            uint256 reward = calculateReward(
                msg.sender,
                correct
            );
            return reward;
        }
        return 0;
    }

    function verifiedPrediction() external view returns(bool){
        return predictions[msg.sender].verifiedPrediction;
    }

    function getMarketId() external view returns(uint256){
        return marketId;
    }

    function getReputationTokenAddress() external view returns(address){
        return reputationTokenAddress;
    }

    function calculateReward(
        address _userAddress,
        bool correct
    ) internal view returns(uint256){
        if(!correct){
            return 0;
        }else{
            uint256 result = 1;
            uint256 timeAfterPrediction = (
                wageDeadline - predictions[_userAddress].predictionTimestamp
            );
            uint256 marketLength = (
                wageDeadline - creationDate
            );
            
            result *= MULTIPLIER;
            result *= (
                MathContract.ln(marketLength, LNDENOMINATION) *
                timeAfterPrediction /
                marketLength /
                10 ** LNDENOMINATION
            );
            result *= (
                MathContract.ln(numberOfOutcomes, LNDENOMINATION) / 
                10 ** LNDENOMINATION
            );
            return result;
        }
    }

    function resolve() external virtual;

    function _verifyPrediction(
        bytes32 _signatureHash,
        uint256 _decodedPrediction,
        bytes calldata _signature
    ) internal view returns(bool){
        require(
            keccak256(abi.encodePacked(_signature)) == _signatureHash,
            "submited wrong signature"
        );
        bytes32 _messageHash = keccak256(
            abi.encodePacked(msg.sender, _decodedPrediction, marketId)
        );
        bool verified = SignatureVerifier.verify(
            msg.sender,
            _messageHash,
            _signature
        );
        return verified;
    }

    function _generateMarketId(
        string memory _question
    ) internal view virtual returns(uint256){
        return uint256(
            keccak256(
                abi.encodePacked(block.number, block.timestamp, _question)
            )
        );
    }

    function _getMarketOutcome() internal view virtual returns(uint256);
}