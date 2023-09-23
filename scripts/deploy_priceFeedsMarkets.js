const { ethers } = require("hardhat");
const { BigNumber, utils } = require("ethers");
const faker = require('faker');

const assetPairs = [
    'BTC/USD',
    'DAI/USD',
    'ETH/USD'
]

const pythiaFactoryAddress = "0xe96806817eF13f38E2eb9fb8e5B7128701b76b36";
const priceFeederAddress = "0x03F2168Fedf95A9c5a965A8eF5e05E12F93395af";

const priceFeedsAddresses = [
    "0x007A22900a3B98143368Bd5906f8E17e9867581b",
    "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
    "0x0715A7794a1dc8e42615F059dD6e406A6594651A"
]

const reputationToken = "0x6ebb69dd2479e3e75fc9bff039543f9623e19c75";

const assetPriceRanges = [
    [24000, 250000],
    [0.999, 1.001],
    [1400, 1600]
]

const constructQuestion = (assetPair) => {
    return `What will be the price of ${assetPair}`
} 

const priceToBigInt = (price) => {
    return utils.parseEther(price.toString());
}

const getOutcomes = (index) => {
    const price = faker.datatype.number(
        { 
            min: assetPriceRanges[index][0],
            max: assetPriceRanges[index][1],
            precision: assetPriceRanges[index][0] * 0.1
        }
    )
    return [priceToBigInt(price), 0, 0, 0, 0]
}

const getDate = () => {
    return Math.floor(Date.now() / 1000) + faker.datatype.number(
        { 
            min: 600,
            max: 3600 * 2
        }
    )
}


const createFakePriceFeedsMarketParams = () => {

   const index = faker.datatype.number({ min: 0, max: assetPairs.length  - 1 })
   const date = getDate()

   const assetPair = assetPairs[index]

   return {
        _question: constructQuestion(assetPairs[index]),
        _outcomes: getOutcomes(index),
        _numberOfOutcomes: 2,
        _wageDeadline: date,
        _resolutionDate: date,
        _priceFeedAddress: priceFeedsAddresses[index],
        _priceFeederAddress: priceFeederAddress,
        _reputationTokenAddress: reputationToken

   }

}

async function main(n_markets){
    const pythiaFactory = await ethers.getContractAt(
        "PythiaFactory",
        pythiaFactoryAddress
    );

    let parameters;
    let tx;
    for(let i = 0; i < n_markets; i++){
        parameters = createFakePriceFeedsMarketParams();
        await pythiaFactory.createPriceFeedsMarket(
            parameters._question,
            parameters._outcomes,
            parameters._numberOfOutcomes,
            parameters._wageDeadline,
            parameters._resolutionDate,
            parameters._priceFeedAddress,
            parameters._priceFeederAddress,
            parameters._reputationTokenAddress
        )
        console.log("transaction resolved")
    }
}

main(5).catch((error) => {
    console.error(error);
    process.exitCode = 1;
});