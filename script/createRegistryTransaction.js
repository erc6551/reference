const nickMethod = require("nick-method/src/index");
const fs = require("fs");
const path = require("path");

async function main() {
  const registryData = JSON.parse(
    fs.readFileSync(
      path.resolve(
        __dirname,
        "../out/ERC6551Registry.sol/ERC6551Registry.json"
      ),
      "utf-8"
    )
  );

  let tx = {
    nonce: 0,
    gasPrice: 10000000000000,
    gasLimit: 160000,
    value: 0,
    data: registryData.bytecode.object,
  };

  const nickMethodTx = nickMethod.generateNickMethodConfigForContractDeployment(
    tx,
    {
      r: "0x7340000000000000000000000000000000000000000000000000000000000734",
      s: "0x7347347347347347347347347347347347347347347347347347347347347340",
    }
  );

  console.log(nickMethodTx);
}

main();
