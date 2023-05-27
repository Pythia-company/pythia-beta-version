const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const { ethers } = require("hardhat");
const { logger } = require("ethers");
const {solidityKeccak256, solidityPack, AbiCoder, keccak256} = ethers.utils;


describe("SignatureVerifier", () => {
    it("verify", async function(){
        const SignatureVerifier = await ethers.getContractFactory(
            "SignatureVerifier"
        );
        const sg = await SignatureVerifier.deploy();
        await sg.deployed();

        const accounts = await ethers.getSigners(2);
        const messageHash = solidityKeccak256(
            ["uint256", "address", "address"],
            [2, accounts[0].address, accounts[1].address]
        );
        const signature = accounts[0].signMessage(ethers.utils.arrayify(messageHash));
        expect(await sg.verify(
            accounts[0].address,
            messageHash,
            signature
        )).to.eq(true);
    })
});