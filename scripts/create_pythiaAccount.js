const { ethers } = require("hardhat");
const { BigNumber, utils } = require("ethers");
const faker = require('faker');

const pythiaFactoryAddress = "0x36f9023054D54d13fb4d8222689Df79DDE5BF344";

async function main(){
    const pythiaFactory = await ethers.getContractAt(
        "PythiaFactory",
        pythiaFactoryAddress
    );
    await pythiaFactory.createAccount();
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});