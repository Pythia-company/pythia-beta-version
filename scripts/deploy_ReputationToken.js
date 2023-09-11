const { ethers } = require("hardhat");

async function main(){
    //deploy math library
    const ReputationToken = await ethers.getContractFactory("ReputationToken");
    const reputationToken = await ReputationToken.deploy(
        "defi",
        "DEFITOK"
    );
    await reputationToken.deployed();
    console.log(`reputation token address:${reputationToken.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});