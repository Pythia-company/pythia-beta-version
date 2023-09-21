const { ethers } = require("hardhat");
const {solidityKeccak256, solidityPack, keccak256} = ethers.utils;

// const pythiaFactoryAddress = "0xc395145D19136Eb55eA9bdA44EdFdBC40287bcC7";
const marketAddress = "0xD22ce13F3D7BA0a692864CAc01249Fc498109077";
const decodedPrediction = 0;

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC);
const pk = process.env.PRIVATE_KEY;

const user = new ethers.Wallet(
    pk,
    provider
)


async function createPrediction(decodedPrediction, market, user){
    const message = solidityPack(
        ['uint256', 'address', 'address'],
        [decodedPrediction, user.address, market]
    );
    const messageHash = keccak256(
        message
    )
    const signature = await user.signMessage(
        ethers.utils.arrayify(messageHash)
    );
    const encodedPrediction = solidityKeccak256(["bytes"], [signature]);
    return encodedPrediction;
}

async function main(){

    const market =  await ethers.getContractAt(
        "PriceFeedsMarket",
        marketAddress
    );
    await market.predict(
        createPrediction(decodedPrediction, marketAddress, user)
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});