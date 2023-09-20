const { ethers } = require("hardhat");

const pythiaFactoryAddress = "0x36f9023054D54d13fb4d8222689Df79DDE5BF344";

async function main(){
    const pythiaFactory = await ethers.getContractAt(
        "PythiaFactory",
        pythiaFactoryAddress
    );
    await pythiaFactory.deployReputationToken(
        "defi",
        "DEFIREP"
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});