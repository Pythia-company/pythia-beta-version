// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library MathContract{

    uint256 public constant defaultDenomination = 10;

    function ln(
        uint256 x,
        uint256 _denomination
    ) validDenomination(_denomination) validLogInput(x) public pure returns (uint) {
        uint256 one = 10 ** 11;
        uint256 log2_e = 14426950409;
        uint256 denominationDiff = defaultDenomination - _denomination;
        log2_e /= 10 ** denominationDiff;
        one /= 10 ** denominationDiff;
        x *=  10 ** _denomination;
    
        uint256 ilog2 = floorLog2(x / one);
        uint256 z = (x >> ilog2);
        uint256 term = (z - one) * one / (z + one);
        uint256 halflnz = term;
        uint256 termpow = term * term / one * term / one;
        halflnz += termpow / 3;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 5;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 7;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 9;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 11;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 13;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 15;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 17;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 19;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 21;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 23;
        termpow = termpow * term / one * term / one;
        halflnz += termpow / 25;
        return (ilog2 * one) * one / log2_e + 2 * halflnz;
    }

    function floorLog2(uint256 x) public pure returns (uint256) {
        uint256 n;
        if (x >= 2**128) { x >>= 128; n += 128;}
        if (x >= 2**64) { x >>= 64; n += 64;}
        if (x >= 2**32) { x >>= 32; n += 32;}
        if (x >= 2**16) { x >>= 16; n += 16;}
        if (x >= 2**8) { x >>= 8; n += 8;}
        if (x >= 2**4) { x >>= 4; n += 4;}
        if (x >= 2**2) { x >>= 2; n += 2;}
        if (x >= 2**1) { x >>= 1; n += 1;}
        return n;
    }

    modifier validDenomination(uint256 _denomination){
        if(_denomination < defaultDenomination){
            _;
        }
    }
    modifier validLogInput(uint256 x){
        if(x > 0){
            _;
        }
    }
}