// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ReputationToken is Ownable{

    string name;
    string symbol;

    mapping(address => uint256) private ratings;

    event NewOperator(address indexed _operator);

    event Rating(address _rated, uint256 _rating);


    constructor(string memory _name, string memory _symbol) Ownable() {
        name = _name;
        symbol = _symbol;
    }


    /// @notice Rate an address.
    ///  MUST emit a Rating event with each successful call.
    /// @param _rated Address to be rated.
    /// @param _rating Total EXP tokens to reallocate.
    function rate(address _rated, uint256 _rating) external onlyOwner{
        ratings[_rated] += _rating;
        emit Rating(_rated, _rating);
    }


    /// @notice Return a rated address' rating.
    /// @dev MUST register each time `Rating` emits.
    ///  SHOULD throw for queries about the zero address.
    /// @param _rated An address for whom to query rating.
    /// @return int8 The rating assigned.
    function ratingOf(address _rated) external view returns (uint256){
        return ratings[_rated];
    }

}