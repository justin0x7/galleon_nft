const { expect } = require("chai");
const { ethers } = require("hardhat");

const { deploy, bigNum, smallNum } = require("../scripts/utils");

describe("GALLToken test", function () {
  let price = bigNum(15, 18);
  before(async function () {
    [this.deployer, this.user_1, this.royaltyWallet] = await ethers.getSigners();

    this.testToken = await deploy("TestERC20", "TestERC20", "test", "test");
    this.GALLToken = await deploy(
      "GALLToken",
      "GALLToken",
      "testURI",
      this.testToken.address,
      this.royaltyWallet.address,
      BigInt(price)
    );
  });

  it("check deployment", async function () {
    console.log("deployed successfully!");
  });

  it("mint 100 tokens", async function () {
    await expect(
      this.GALLToken.connect(this.user_1).mint(100)
    ).to.be.revertedWith("not enough balance to mint");

    await this.testToken.transfer(this.user_1.address, bigNum(8000, 18));
    await this.testToken
      .connect(this.user_1)
      .approve(this.GALLToken.address, BigInt(price) * BigInt(100));

    await this.GALLToken.connect(this.user_1).mint(100);
  });

  it("reverted if mint cnt is over maxCnt without setting extra option", async function () {
    await expect(
      this.GALLToken.connect(this.user_1).mint(150)
    ).to.be.revertedWith("cannot mint more");
  });

  it("set extra option and mint more & check royalty", async function () {
    await this.GALLToken.setExtraInfo(bigNum(20, 18));
    let requirePrice = BigInt(bigNum(20, 18)) * BigInt(150);
    let royaltyAmount = BigInt(requirePrice) * BigInt(5) / BigInt(100); // 5% royalty
    let beforeRoyaltyBal = await this.testToken.balanceOf(this.royaltyWallet.address);

    expect (smallNum(royaltyAmount, 18)).to.be.greaterThan(0);

    await this.testToken
      .connect(this.user_1)
      .approve(this.GALLToken.address, requirePrice);
    await this.GALLToken.connect(this.user_1).mint(150);

    let afterRoyaltyBal = await this.testToken.balanceOf(this.royaltyWallet.address);
    expect (
      smallNum(BigInt(afterRoyaltyBal) - BigInt(beforeRoyaltyBal), 18)
    ).to.be.equal(smallNum(royaltyAmount, 18));
  });

  it("withdraw tokens", async function () {
    let expectBal = await this.testToken.balanceOf(this.GALLToken.address);
    let beforeBal = await this.testToken.balanceOf(this.deployer.address);
    await this.GALLToken.withdraw();
    let afterBal = await this.testToken.balanceOf(this.deployer.address);

    expect(smallNum(BigInt(afterBal) - BigInt(beforeBal), 18)).to.be.equal(
      smallNum(expectBal, 18)
    );
  });
});
