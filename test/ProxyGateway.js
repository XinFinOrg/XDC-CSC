const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("proxyGateway", () => {
  let proxyGateway;
  let full;
  let lite;

  const fixture = async () => {
    const fullFactory = await ethers.getContractFactory("FullCheckpoint");
    const full = await fullFactory.deploy();

    const liteFactory = await ethers.getContractFactory("LiteCheckpoint");
    const lite = await liteFactory.deploy();
    const factory = await ethers.getContractFactory("ProxyGateway");
    const proxyGateway = await factory.deploy();

    return { proxyGateway, full, lite };
  };

  beforeEach("deploy fixture", async () => {
    ({ proxyGateway, full, lite } = await loadFixture(fixture));
  });

  describe("test proxyGateway", () => {
    it("should create full and lite proxy", async () => {
      await proxyGateway.createFullProxy(
        full.address,
        [
          "0x10982668af23d3e4b8d26805543618412ac724d4",
          "0x6f3c1d8ba6cc6b6fb6387b0fe5d2d37a822b2614",
          "0x80f489a673042c2e5f17e5b2a5e49d71bf0611a4",
          "0xb51df3658799cccb48c172d54e3bc89649f04eb4",
          "0xd23cf44b862ba86703f11f6e94a4a833f4fe2244",
        ],
        "0xf902bea00000000000000000000000000000000000000000000000000000000000000000a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347940000000000000000000000000000000000000000a03a9114857792f2a10b4d04ded4e29cb2371535ed749a7686aa2e9885c6007e25a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001808347b760808464d68a93b8c5000000000000000000000000000000000000000000000000000000000000000010982668af23d3e4b8d26805543618412ac724d46f3c1d8ba6cc6b6fb6387b0fe5d2d37a822b261480f489a673042c2e5f17e5b2a5e49d71bf0611a4b51df3658799cccb48c172d54e3bc89649f04eb4d23cf44b862ba86703f11f6e94a4a833f4fe22440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000088000000000000000080c0c0c0",
        "0xf902cfa0c2e6a789316fe7112553ef911649f2d19380ce6746288b9fa6fc5af8ad16ef2aa01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d493479480f489a673042c2e5f17e5b2a5e49d71bf0611a4a03a9114857792f2a10b4d04ded4e29cb2371535ed749a7686aa2e9885c6007e25a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421b90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101841908b100808464d68e35aa02e802e6e3a0c2e6a789316fe7112553ef911649f2d19380ce6746288b9fa6fc5af8ad16ef2a8080c080a00000000000000000000000000000000000000000000000000000000000000000880000000000000000b841160324f07543714bd91d4576bc74a6fe8c0aa706781ed943479a5ee0d9c2ed75174a776ee736030bb0d080947514d83c69ed328c69661409341c317fcacf855b00c0f8699410982668af23d3e4b8d26805543618412ac724d4946f3c1d8ba6cc6b6fb6387b0fe5d2d37a822b26149480f489a673042c2e5f17e5b2a5e49d71bf0611a494b51df3658799cccb48c172d54e3bc89649f04eb494d23cf44b862ba86703f11f6e94a4a833f4fe2244c0",
        450,
        900
      );
      await proxyGateway.createLiteProxy(
        lite.address,
        [
          "0x10982668af23d3e4b8d26805543618412ac724d4",
          "0x6f3c1d8ba6cc6b6fb6387b0fe5d2d37a822b2614",
          "0x80f489a673042c2e5f17e5b2a5e49d71bf0611a4",
          "0xb51df3658799cccb48c172d54e3bc89649f04eb4",
          "0xd23cf44b862ba86703f11f6e94a4a833f4fe2244",
        ],
        "0xf902cfa0994512611cf80029bf4de5f214437e6c47841ab8730cd7598dfb04b606af91a3a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d493479480f489a673042c2e5f17e5b2a5e49d71bf0611a4a03a9114857792f2a10b4d04ded4e29cb2371535ed749a7686aa2e9885c6007e25a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421b90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101841908b100808464d21493aa02e802e6e3a0994512611cf80029bf4de5f214437e6c47841ab8730cd7598dfb04b606af91a38080c080a00000000000000000000000000000000000000000000000000000000000000000880000000000000000b841cadb57e92efb44f8614c1c13d0fbb7f19bc7e5a2d6d84a211fda0bf59cff283c387689979dd2c989265ebdcca9aeb96d6701253502ccf83d5e052be1dfbea19d00c0f8699410982668af23d3e4b8d26805543618412ac724d4946f3c1d8ba6cc6b6fb6387b0fe5d2d37a822b26149480f489a673042c2e5f17e5b2a5e49d71bf0611a494b51df3658799cccb48c172d54e3bc89649f04eb494d23cf44b862ba86703f11f6e94a4a833f4fe2244c0",
        450,
        900
      );
      const fullProxyAddress = await proxyGateway.cscProxies(0);
      const liteProxyAddress = await proxyGateway.cscProxies(1);

      const fullProxy = full.attach(fullProxyAddress);
      const liteProxy = lite.attach(liteProxyAddress);

      const fullMode = await fullProxy.MODE();
      const fullGap = await fullProxy.INIT_GAP();

      const liteMode = await liteProxy.MODE();
      const liteGap = await liteProxy.INIT_GAP();

      expect(full.address).to.not.eq(fullProxy.address);
      expect(fullMode).to.eq("full");
      expect(fullGap).to.eq(450);

      expect(lite.address).to.not.eq(liteProxy.address);
      expect(liteMode).to.eq("lite");
      expect(liteGap).to.eq(450);
    });

    it("should upgrade success", async () => {
      await proxyGateway.createFullProxy(
        full.address,
        [
          "0x10982668af23d3e4b8d26805543618412ac724d4",
          "0x6f3c1d8ba6cc6b6fb6387b0fe5d2d37a822b2614",
          "0x80f489a673042c2e5f17e5b2a5e49d71bf0611a4",
          "0xb51df3658799cccb48c172d54e3bc89649f04eb4",
          "0xd23cf44b862ba86703f11f6e94a4a833f4fe2244",
        ],
        "0xf902bea00000000000000000000000000000000000000000000000000000000000000000a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347940000000000000000000000000000000000000000a03a9114857792f2a10b4d04ded4e29cb2371535ed749a7686aa2e9885c6007e25a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001808347b760808464d68a93b8c5000000000000000000000000000000000000000000000000000000000000000010982668af23d3e4b8d26805543618412ac724d46f3c1d8ba6cc6b6fb6387b0fe5d2d37a822b261480f489a673042c2e5f17e5b2a5e49d71bf0611a4b51df3658799cccb48c172d54e3bc89649f04eb4d23cf44b862ba86703f11f6e94a4a833f4fe22440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000088000000000000000080c0c0c0",
        "0xf902cfa0c2e6a789316fe7112553ef911649f2d19380ce6746288b9fa6fc5af8ad16ef2aa01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d493479480f489a673042c2e5f17e5b2a5e49d71bf0611a4a03a9114857792f2a10b4d04ded4e29cb2371535ed749a7686aa2e9885c6007e25a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421b90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101841908b100808464d68e35aa02e802e6e3a0c2e6a789316fe7112553ef911649f2d19380ce6746288b9fa6fc5af8ad16ef2a8080c080a00000000000000000000000000000000000000000000000000000000000000000880000000000000000b841160324f07543714bd91d4576bc74a6fe8c0aa706781ed943479a5ee0d9c2ed75174a776ee736030bb0d080947514d83c69ed328c69661409341c317fcacf855b00c0f8699410982668af23d3e4b8d26805543618412ac724d4946f3c1d8ba6cc6b6fb6387b0fe5d2d37a822b26149480f489a673042c2e5f17e5b2a5e49d71bf0611a494b51df3658799cccb48c172d54e3bc89649f04eb494d23cf44b862ba86703f11f6e94a4a833f4fe2244c0",
        450,
        900
      );
      const fullProxyAddress = await proxyGateway.cscProxies(0);
      const fullProxy = full.attach(fullProxyAddress);
      const fullMode = await fullProxy.MODE();
      const fullGap = await fullProxy.INIT_GAP();
      const fullResult = await fullProxy.getHeaderByNumber(1);

      expect(full.address).to.not.eq(fullProxy.address);
      expect(fullMode).to.eq("full");
      expect(fullGap).to.eq(450);

      const proxyTestFactory = await ethers.getContractFactory("ProxyTest");
      const proxyTest = await proxyTestFactory.deploy();

      await proxyGateway.upgrade(fullProxyAddress, proxyTest.address);
      const afterUpgradeResult = await fullProxy.getHeaderByNumber(1);

      expect(fullResult[0]).to.eq(
        "0x684d18e0081cbe82cab66173647eaf2b078413da5f79a1082a5228314c23ae15"
      );
      expect(fullResult[1]).to.eq(1);

      expect(afterUpgradeResult[0]).to.eq(
        "0x0000000000000000000000000000000000000000000000000000000000000666"
      );
      expect(afterUpgradeResult[1]).to.eq(666);
    });
  });
});
