// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/SignatureVerifier.sol";
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
    bool resolved;
    uint256 answer;
    
    mapping(address => Prediction) public predictions;

    constructor(
        address _factoryContractAddress,
        string memory _question,
        uint256 _numberOfOutcomes,
        uint256 _wageDeadline,
        uint256 _resolutionDate
    ){  
        pythiaFactory = PythiaFactory(_factoryContractAddress);
        numberOfOutcomes = _numberOfOutcomes;
        creationDate = block.timestamp;
        question = _question;
        wageDeadline = _wageDeadline;
        resolutionDate = _resolutionDate;
        resolved = false;
    }

    function predict(bytes32 _encodedPrediction) external {
        require(
            block.timestamp <= wageDeadline,
            "market is not active"
        );
        require(pythiaFactory.isUser(msg.sender), "user is not registered");
        require(
            (
                (pythiaFactory.isSubscribed(msg.sender) == true) ||
                (pythiaFactory.isInTrial(msg.sender) == true)
            ),
            "trial has expired, subscribe to make predictions"
        );
        require(predictions[msg.sender].predicted == false, "user has already predicted");
        predictions[msg.sender].encodedPrediction = _encodedPrediction;
        predictions[msg.sender].predictionTimestamp = block.timestamp;
        predictions[msg.sender].predicted = true;
    }

    function disclosePrediction(
        uint256 _decodedPrediction,
        bytes calldata _signature
    ) external returns(uint256){
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
            abi.encodePacked(msg.sender, _decodedPrediction, address(this))
        );
        bool verified = SignatureVerifier.verify(
            msg.sender,
            _messageHash,
            _signature
        );
        return verified;
    }

    function _getMarketOutcome() internal view virtual returns(uint256);
}