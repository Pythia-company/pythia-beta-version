const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const { ethers } = require("hardhat");
const {solidityKeccak256, solidityPack, keccak256} = ethers.utils;

describe("TestMarket", function () {
    async function deployTestMarket(){
        //get accounts
        const accounts = await ethers.getSigners(1);

        //deploy math library
        const Maths = await ethers.getContractFactory("Maths");
        const maths = await Maths.deploy();
        await maths.deployed();

        //deploy signature verifier
        const SignatureVerifier = await ethers.getContractFactory("SignatureVerifier");
        const signatureVerifier = await SignatureVerifier.deploy();
        await signatureVerifier.deployed();

        //deploy abstract market
        const params = {
            _question: "In what range will USDC be by 12/06/2023",
            _numberOfOutcomes: 2,
            _wageDeadline: 1686573804000,
            _resolutionDate: 1686573804000
        }
        const TestMarket= await ethers.getContractFactory(
            "TestMarket",
            {
                libraries: {
                    "Maths": maths.address,
                    "SignatureVerifier": signatureVerifier.address
                }
            }
        );
        const testMarket = await TestMarket.deploy(
            params._question,
            params._numberOfOutcomes,
            params._wageDeadline,
            params._resolutionDate
        );
        await testMarket.deployed();
        return {
            testMarket,
            params
        }

    }

    async function createPrediction(decodedPrediction, market, user){
        const message = solidityPack(
            ['uint256', 'address', 'address'],
            [decodedPrediction, user.address, market]
        );
        const messageHash = keccak256(
            message
        )
        const signature = await user.signMessage(
            ethers.utils.arrayify(messageHash)
        );
        return signature;
    }

    async function generateRandomSignature(user){
        const randomInt = Math.floor(Math.random() * 10) + 10
        return await user.signMessage(
            solidityPack(["uint256"], [randomInt])
        );
    }


    describe("Deployment", () => {
        //testng that all variables are initialized correctly in constructor
        it("constructor", async function(){
            const {testMarket, params} = await loadFixture(
                deployTestMarket
            );
            expect(
                (await testMarket.wageDeadline()).toString()
            ).to.be.equal(
                params._wageDeadline.toString()
            );
            expect(
                (await testMarket.resolutionDate()).toString()
            ).to.be.equal(
                params._resolutionDate.toString()
            );
            expect((await testMarket.numberOfOutcomes()).toString()).to.be.equal(
                params._numberOfOutcomes.toString()
            );
        });
    });


    describe("Prediction", () => {
        //testing prediction mechanism
        it("predict", async function(){
            const accounts = await ethers.getSigners(1);
            const {testMarket, params} = await loadFixture(
                deployTestMarket
            );
            const decodedPrediction = 2;
            const signature = await createPrediction(
                decodedPrediction,
                testMarket.address,
                accounts[0]
            )
            let tx = await testMarket.connect(accounts[0]).predict(
                solidityKeccak256(["bytes"], [signature])
            );
            await tx.wait();

            //check prediction
            expect(await testMarket.hasPredicted(
                accounts[0].address)
            ).to.be.equal(
                true
            );

            //verify that can't predict second time
            await expect(
                testMarket.connect(accounts[0]).predict(
                    solidityKeccak256(["bytes"], [signature])
                )
            ).to.be.revertedWith(
                "user has already predicted"
            );

            //verify that can't predict after wage deadline
            await time.increaseTo(
                params._wageDeadline + 1
            );
            await expect(
                testMarket.connect(accounts[0]).predict(
                    solidityKeccak256(["bytes"], [signature])
                )
            ).to.be.revertedWith(
                "market is no longer active"
            );
        });
        //testing prediction verification
        it("verifyPrediction", async function(){
            //get vars
            const accounts = await ethers.getSigners(1);
            const decodedPrediction = 2;
            const {testMarket, params} = await loadFixture(
                deployTestMarket
            );

            //creaet signature
            const signature = await createPrediction(
                decodedPrediction,
                testMarket.address,
                accounts[0]
            )
    

            //check that can't verify before prediction
            await expect(
                testMarket.verifyPrediction(
                    decodedPrediction,
                    signature
                )
            ).to.be.revertedWith(
                "user has not predicted"
            );

            let tx = await testMarket.connect(accounts[0]).predict(
                solidityKeccak256(["bytes"], [signature])
            )
            await tx.wait();
            //test revert with wrong signature
            const randomSignature = await generateRandomSignature(accounts[0]);

            // revert with wrong signature
            await expect(
                testMarket.verifyPrediction(
                    decodedPrediction,
                    randomSignature
                )
            ).to.be.revertedWith(
                "submited wrong signature"
            );

            //test incorrect prediction verification
            tx  = await testMarket.verifyPrediction(
                decodedPrediction + 1,
                signature
            );
            await tx.wait();
            expect(await testMarket.verifiedPrediction(
                accounts[0].address)
            ).to.be.equal(
               false
            );

            //verify prediction
            tx  = await testMarket.connect(accounts[0]).verifyPrediction(
                decodedPrediction,
                signature
            );
            await tx.wait();

            expect(await testMarket.verifiedPrediction(
                accounts[0].address)
            ).to.be.equal(
               true
            );

            //check that can't verify twice
            await expect(
                testMarket.verifyPrediction(
                    decodedPrediction,
                    signature
                )
            ).to.be.revertedWith(
                "you have already verified your prediction"
            );
        });
    });
});