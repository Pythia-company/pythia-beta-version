const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Maths", function (){
    it("computeReputation", async function(){
        const Maths = await ethers.getContractFactory(
            "Maths"
        );
        const maths = await Maths.deploy();
        await maths.deployed();
        
        const wageDeadline = 1687871012000;
        const creationDate = 1687870000000;
        const numberOfOutcomes = 5;
        const predictionTimestamp = 1687870000000;
        const rewardDenomination = 6;

        const timeBeforeDeadline = (
            wageDeadline - predictionTimestamp
        );
        const marketLength = (
            wageDeadline - creationDate
        );

        const logMarketLength = (
            Math.log(marketLength)
        );

        const logNumberOfOutcomes = (
            Math.log(numberOfOutcomes)
        );
        //replicate reward computation
        const rewardComputedExternally = (
            10 ** rewardDenomination *
            logMarketLength *
            logNumberOfOutcomes *
            timeBeforeDeadline /
            marketLength
        );

        const reward = await maths.computeReputation(
            wageDeadline,
            creationDate,
            predictionTimestamp,
            numberOfOutcomes
        )
        const maxOfRewards = Math.max(rewardComputedExternally, reward);
        //check that margin of error is less than 5%
        expect((maxOfRewards - reward)/ maxOfRewards < 0.05).to.eq(true);
    });
});