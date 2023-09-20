const { ethers } = require("hardhat");

async function main(){
    //deploy math library
    const Maths = await ethers.getContractFactory("Maths");
    const maths = await Maths.deploy();
    await maths.deployed();

    //deploy signature verifier
    const SignatureVerifier = await ethers.getContractFactory("SignatureVerifier");
    const signatureVerifier = await SignatureVerifier.deploy();
    await signatureVerifier.deployed();

    //deploy market Deployer library
    const MarketDeployer = await ethers.getContractFactory(
        "MarketDeployer",
        {
            libraries: {
                "Maths": maths.address,
                "SignatureVerifier": signatureVerifier.address
            }
        }
    );
    const marketDeployer = await MarketDeployer.deploy();
    await marketDeployer.deployed();


     //deploy reputation token deployer
     const ReputationTokenDeployer = await ethers.getContractFactory("ReputationTokenDeployer");
     const reputationTokenDeployer = await ReputationTokenDeployer.deploy();
     await reputationTokenDeployer.deployed();
 
    //deploy pythia factory
    const params = {
        _trialPeriodDays: 30,
        _subscriptionTokenAddress: "0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747",
        _treasuryAddress: "0xFfeEcd85edF58666AEb95Cc2EFA855DA62E6ea56",
        _baseAmountRecurring: ethers.utils.parseEther('30')
    }

    const PythiaFactory = await ethers.getContractFactory(
        "PythiaFactory",
        {
            libraries: {
                "MarketDeployer": marketDeployer.address,
                "ReputationTokenDeployer": reputationTokenDeployer.address
            }
        }
    );
    const pythiaFactory = await PythiaFactory.deploy(
        params._trialPeriodDays,
        params._subscriptionTokenAddress,
        params._treasuryAddress,
        params._baseAmountRecurring
    );
    await pythiaFactory.deployed();
    console.log(`pythia factory address:${pythiaFactory.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});