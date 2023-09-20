const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const { ethers } = require("hardhat");

describe("Pythia Factory", function () {
    async function deployPythiaFactory(){
        //get accounts
        const accounts = await ethers.getSigners(4);

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
            _subscriptionTokenAddress: accounts[1].address,
            _treasuryAddress: accounts[2].address,
            _baseAmountRecurring: 10**6
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
        return {
            pythiaFactory,
            params
        }

    }
    describe("Deployment", function(){
        it("trialPeriod", async function(){
            const {pythiaFactory, params} = await loadFixture(
                deployPythiaFactory
            );
            expect(
                (await pythiaFactory.trialPeriod()).toString()
            ).to.be.equal(
                (params._trialPeriodDays * 3600 * 24).toString()
            );
        });

    });

    describe("Account", function(){

        //check status after creating account
        it("createAccount", async function () {
            const accounts = await ethers.getSigners(1);
            const {pythiaFactory, params} = await loadFixture(deployPythiaFactory);
            const tx = await pythiaFactory.connect(accounts[0]).createAccount();
            await tx.wait();
            //check success
            expect(await pythiaFactory.isUser(accounts[0].address)).to.equal(
                true
            );
            //check revert
            await expect(pythiaFactory.connect(accounts[0]).createAccount()).to.be.revertedWith(
                "user already exists"
            );
        });
        it("Trial time dependency", async function () {
            const accounts = await ethers.getSigners(2);
            const {pythiaFactory, params} = await loadFixture(deployPythiaFactory);
            //create account
            const tx = await pythiaFactory.connect(accounts[0]).createAccount();
            await tx.wait();
            //check that true
            expect(await pythiaFactory.isInTrial(accounts[0].address)).to.be.equal(true);
            const now = Date.now();
            await time.increase((params._trialPeriodDays + 1) * 24 * 3600);

            //check that false
            expect(
                await pythiaFactory.isInTrial(accounts[0].address)
            ).to.be.equal(false);
        });
    });
});