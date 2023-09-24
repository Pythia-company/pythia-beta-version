const { ethers } = require("hardhat");
const { BigNumber, utils } = require("ethers");
const faker = require('faker');

const pythiaFactoryAddress = "0x461BADd2e33f7CDF238d7Fd79Ad7758AcBa3E795";

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