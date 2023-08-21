const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Perp", function () {
  async function deploy(WETH) {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Perp = await ethers.getContractFactory("Perp");
    const perp = await Perp.deploy(
      "0xcf205808ed36593aa40a44f10c7f7c2f67d4a4d4",
      "0xcf205808ed36593aa40a44f10c7f7c2f67d4a4d4",
      "0xcf205808ed36593aa40a44f10c7f7c2f67d4a4d4"
    );

    return { perp, owner, otherAccount };
  }

  async function deployWETH() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const WETH = await ethers.getContractFactory("WETH");
    const weth = await WETH.deploy(10000000);

    return { weth, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right owner for Perp.sol", async function () {
      const { perp, owner } = await loadFixture(deploy);

      expect(await perp.owner()).to.equal(owner.address);
    });

    it("Set correct WETH balance", async function () {
      const { weth, owner } = await loadFixture(deployWETH);

      expect(await weth.balanceOf(owner.address)).to.equal(10000000);
    });
  });

  describe("LP", function () {
    it("Add LP", async function () {
      const { weth } = await loadFixture(deployWETH);
      const { perp, owner } = await loadFixture(deploy);

      await weth.approve(perp.target, 1000);
      await perp.lpAdd(1000);

      expect(await perp.lpShare(owner.address)).to.equal(1000);
    });
  });

  describe("Trade", function () {
    it("Open position", async function () {
      const { weth } = await loadFixture(deployWETH);
      const { perp, owner } = await loadFixture(deploy);

      await weth.approve(perp.target, 1000);
      await perp.open(1000, 800, true);

      expect(await perp.positionOf(owner.address)).to.equal(true);
    });

    it("Close position", async function () {
      const { perp, owner } = await loadFixture(deploy);

      await perp.close();

      expect(await perp.positionOf(owner.address)).to.equal(false);
    });
  });
});
