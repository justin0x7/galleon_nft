const { expect } = require("chai");
const { ethers } = require("hardhat");

const { deploy, bigNum, smallNum } = require("../scripts/utils");

describe("GALLNFT test", function () {
  let price = bigNum(15, 18);
  let airdropAmount = bigNum(10, 18);
  let tokenId;
  before(async function () {
    [this.deployer, this.user_1, this.royaltyWallet] = await ethers.getSigners();

    this.testToken = await deploy("TestERC20", "TestERC20", "test", "test");
    this.gallToken = await deploy("TestERC20", "TestGALLToken", "test", "test");
    this.GALLNFT = await deploy(
      "GALLNFT",
      "GALLNFT",
      "testURI",
      this.testToken.address,
      this.royaltyWallet.address,
      this.gallToken.address,
      BigInt(price),
      BigInt(airdropAmount)
    );
  });

  it("check deployment", async function () {
    console.log("deployed successfully!");
  });

  it ("revert mint if GallNFT doesn't have enough gallToken for airdrop", async function () {
    tokenId = await this.GALLNFT.tokenId();
    await expect(
      this.GALLNFT.connect(this.user_1).mint(tokenId, 100)
    ).to.be.revertedWith("not enough balance to mint");

    await this.testToken.transfer(this.user_1.address, bigNum(8000, 18));
    await this.testToken
      .connect(this.user_1)
      .approve(this.GALLNFT.address, BigInt(price) * BigInt(100));

    await expect (
      this.GALLNFT.connect(this.user_1).mint(tokenId, 10)
    ).to.be.revertedWith("Insufficient balance");
  })

  it("mint 100 tokens", async function () {
    let balance = await this.gallToken.balanceOf(this.deployer.address);
    await this.gallToken.transfer(this.GALLNFT.address, BigInt(balance));

    let beforeNFTBal = await this.GALLNFT.balanceOf(this.user_1.address, tokenId);
    let beforeTokenBal = await this.gallToken.balanceOf(this.user_1.address);
    await this.GALLNFT.connect(this.user_1).mint(tokenId, 100);
    let afterNFTBal = await this.GALLNFT.balanceOf(this.user_1.address, tokenId);
    let afterTokenBal = await this.gallToken.balanceOf(this.user_1.address);

    let expectTokenAmount = BigInt(airdropAmount) * BigInt(100);
    let afterTokenId = await this.GALLNFT.tokenId();
    expect (BigInt(afterNFTBal) - BigInt(beforeNFTBal)).to.be.equal(BigInt(100));
    expect (smallNum(BigInt(afterTokenBal) - BigInt(beforeTokenBal), 18)).to.be.equal(smallNum(expectTokenAmount, 18));
    expect (Number(afterTokenId) - Number(tokenId)).to.be.equal(1);
  });

  it("reverted if mint cnt is over maxCnt without setting extra option", async function () {
    await expect(
      this.GALLNFT.connect(this.user_1).mint(tokenId, 150)
    ).to.be.revertedWith("cannot mint more");
  });

  it("set extra option and mint more & check royalty", async function () {
    await this.GALLNFT.setExtraInfo(tokenId, bigNum(20, 18));
    let requirePrice = BigInt(bigNum(20, 18)) * BigInt(150);
    let royaltyAmount = BigInt(requirePrice) * BigInt(5) / BigInt(100); // 5% royalty
    let beforeRoyaltyBal = await this.testToken.balanceOf(this.royaltyWallet.address);

    expect (smallNum(royaltyAmount, 18)).to.be.greaterThan(0);

    await this.testToken
      .connect(this.user_1)
      .approve(this.GALLNFT.address, requirePrice);
    await this.GALLNFT.connect(this.user_1).mint(tokenId, 150);

    let afterRoyaltyBal = await this.testToken.balanceOf(this.royaltyWallet.address);
    expect(afterRoyaltyBal.sub(beforeRoyaltyBal)).to.equal(royaltyAmount);
  });

  it("withdraw tokens", async function () {
    let expectBal = await this.testToken.balanceOf(this.GALLNFT.address);
    let beforeBal = await this.testToken.balanceOf(this.deployer.address);
    expect (smallNum(expectBal, 18)).to.be.greaterThan(0);
    await this.GALLNFT.withdraw();
    let afterBal = await this.testToken.balanceOf(this.deployer.address);

    expect(smallNum(BigInt(afterBal) - BigInt(beforeBal), 18)).to.be.equal(
      smallNum(expectBal, 18)
    );
  });
});
