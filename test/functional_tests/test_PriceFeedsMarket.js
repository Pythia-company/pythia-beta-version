const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const { ethers } = require("hardhat");
const {
    priceFeederAddress,
    pythiaFactoryAddress,
    reputationTokenAddress
} = require('./config.json');
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");
require("dotenv").config();
const {sleep} = require('../utils/utils.js');


describe("PriceFeedsMarket", function () {

    async function deployPriceFeedsMarket(params){

        const provider = new ethers.providers.JsonRpcProvider(process.env.RPC);
        const network = await provider.getNetwork();

        // Get the network ID
        const networkId = network.chainId;
        console.log(`network: ${network}`)
        console.log(`networkId: ${networkId}`)
        const wallet = new ethers.Wallet(`0x${process.env.PRIVATE_KEY}`, provider);

        //deploy math library
        const Maths = await ethers.getContractFactory(
            "Maths",
            {
                signer: wallet
            }
        );
        const maths = await Maths.deploy();
        await maths.deployed();
        console.log("deployed math")

        //deploy signature verifier
        const SignatureVerifier = await ethers.getContractFactory(
            "SignatureVerifier",
            {
                signer: wallet
            }
        );
        console.log("deployed signature verifier")
        const signatureVerifier = await SignatureVerifier.deploy();
        await signatureVerifier.deployed();

        const Market= await ethers.getContractFactory(
            "PriceFeedsMarket",
            {
                signer: wallet,
                libraries: {
                    "SignatureVerifier": signatureVerifier.address,
                    "Maths": maths.address
                }
            }
        );
        console.log("created market factory");
        const market = await Market.deploy(
            params._factoryContractAddress,
            params._question,
            params._outcomes,
            params._numberOfOutcomes,
            params._wageDeadline,
            params._resolutionDate,
            params._priceFeedAddress,
            params._priceFeederAddress
        );
        await market.deployed();
        console.log("deployed market");
        return {
            market,
            wallet
        }

    }


    it("testing resolution", async ()=>{
        const delaySeconds = 5;
        const currentTimestamp = Math.floor(Date.now() / 1000);

        const params = {      
            _factoryContractAddress: pythiaFactoryAddress,
            _question: "What will be the price range of ETH/USD",
            _outcomes: [1000, 0, 0, 0, 0],
            _numberOfOutcomes: 2,
            _wageDeadline: currentTimestamp + delaySeconds,
            _resolutionDate: currentTimestamp + delaySeconds,
            _priceFeedAddress: '0x0715A7794a1dc8e42615F059dD6e406A6594651A',
            _priceFeederAddress: priceFeederAddress
        }
        const {market, wallet} = await deployPriceFeedsMarket(params);
        console.log(`market address:${market.address}`)
        await new Promise(
            done => setTimeout(
                () => done(),
                (delaySeconds + 1) * 1000
            )
        );
        // await expect(
        //     await market.connect(wallet).resolve()
        // ).to.be.revertedWith(
        //     "resolution date has not arrived yet"
        // );
        let overrides = {
            gasLimit: 130000,
        };
        const tx = await market.resolve(overrides)
        await tx.wait();
        console.log("resolved");
        expect((await market.answer()).toString()).to.be.eq('1');

    })

});