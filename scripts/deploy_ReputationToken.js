const { ethers } = require("hardhat");

const pythiaFactoryAddress = "0x461BADd2e33f7CDF238d7Fd79Ad7758AcBa3E795";

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