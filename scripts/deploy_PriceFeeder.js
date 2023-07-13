const { ethers } = require("hardhat");

async function main(){
    //deploy math library
    const PriceFeeder = await ethers.getContractFactory("PriceFeeder");
    const pricefeeder = await PriceFeeder.deploy();
    await pricefeeder.deployed();
    console.log(`price feeder address:${pricefeeder.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});