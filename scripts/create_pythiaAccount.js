const { ethers } = require("hardhat");
const { BigNumber, utils } = require("ethers");
const faker = require('faker');

const pythiaFactoryAddress = "0x8fB8Db89414D9f3006133f956C249ba947C2737F";

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