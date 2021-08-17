const { assert } = require("chai");
const fs = require('fs')
const path = require('path')
const Web3 = require('web3');
const web3 = new Web3('http://127.0.0.1:8545');

const BtclToken = artifacts.require("BtclToken");
const MockERC20 = artifacts.require("MockERC20");
const BtclSeedRound = artifacts.require("BtclSeedRound");

module.exports = async function (deployer, network, accounts) {
    if(network !== "kovan") return;

    console.log("ACCOUNTS", accounts)

    await deployer.deploy(BtclToken);
    const btclToken = await BtclToken.deployed();

    await deployer.deploy(MockERC20, "WBTC", "WBTC", 8, 1000000);
    const wbtcToken = await MockERC20.deployed();

    await deployer.deploy(MockERC20, "WETH", "WETH", 18, 1000000);
    const wethToken = await MockERC20.deployed();

    await deployer.deploy(MockERC20, "LINK", "LINK", 18, 1000000);
    const linkToken = await MockERC20.deployed();

    await deployer.deploy(MockERC20, "BNB", "BNB", 18, 1000000);
    const  bnbToken = await MockERC20.deployed();

    await deployer.deploy(MockERC20, "UNI", "UNI", 18, 1000000);
    const  uniToken = await MockERC20.deployed();

    await deployer.deploy(MockERC20, "DAI", "DAI", 18, 1000000);
    const  daiToken = await MockERC20.deployed();

    await deployer.deploy(MockERC20, "USDC", "USDC", 6, 1000000);
    const USDCToken = await MockERC20.deployed();

    await deployer.deploy(MockERC20, "USDT", "USDT", 6, 1000000);
    const USDTToken = await MockERC20.deployed();

    await deployer.deploy(BtclSeedRound,
        0, 0, 0, 0, btclToken.address, 
        [wbtcToken.address, wethToken.address, linkToken.address, bnbToken.address, uniToken.address, daiToken.address, USDCToken.address, USDTToken.address], 
        ["0x6135b13325bfC4B00278B4abC5e20bbce2D6580e", "0x9326BFA02ADD2366b30bacB125260Af641031331", "0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0", "0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16", "0xDA5904BdBfB4EF12a3955aEcA103F51dc87c7C39", "0x777A68032a88E5A84678A77Af2CD65A7b3c0775a", "0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60", "0x2ca5A90D34cA333661083F89D831f757A9A50148"]
    );
    const SeedRound = await BtclSeedRound.deployed();

    const logs = []
    logs.push(
        `BtclToken_addr: "${btclToken.address}"`,
        `WbtcToken_addr: "${wbtcToken.address}"`,
        `WethToken_addr: "${wethToken.address}"`,
        `LinkToken_addr: "${linkToken.address}"`,
        `BnbToken_addr: "${bnbToken.address}"`,
        `UnicToken_addr: "${uniToken.address}"`,
        `DaiToken_addr: "${daiToken.address}"`,
        `UsdcToken_addr: "${USDCToken.address}"`,
        `UsdtToken_addr: "${USDTToken.address}"`,
        `SeedRound_addr: "${SeedRound.address}"`
    )
    try {
        const outputDir = path.join(__dirname, `../e2e_config/${network}`)
        if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir)
        fs.writeFileSync(path.join(outputDir, 'contracts.yml'), logs.join('\n'))
    } catch (err) {
        console.error(err)
    }

    await btclToken.transferAndCall(SeedRound.address, "100000000000000000000000", "0x", {from: accounts[0]});
    await wethToken.approve(SeedRound.address, "1000000000000000000", {from: accounts[0]});

    await SeedRound.multiKycWhitelisting([accounts[0]], [true], {from: accounts[0]});

    await SeedRound.buyTokens(wethToken.address, "100", {from: accounts[0]})

}