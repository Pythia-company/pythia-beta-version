const { ethers } = require("hardhat");

const pythiaFactoryAddress = "0xe96806817eF13f38E2eb9fb8e5B7128701b76b36";

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