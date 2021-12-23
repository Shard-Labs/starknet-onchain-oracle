import { expect } from "chai";
import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory } from "hardhat/types/runtime";

describe("Starknet", function () {
  this.timeout(300_000);
  let oracleAddress;
  let clientAddress;
  let oracleContractFactory: StarknetContractFactory;
  let clientContractFactory: StarknetContractFactory;

  const team1Name = "Brooklyn Nets";
  const team1Int = starknet.stringToBigInt(team1Name);
  const team1Score = BigInt(116);

  const team2Name = "Sacramento Kings";
  const team2Int = starknet.stringToBigInt(team2Name);
  const team2Score = BigInt(97);
  
  const matchDate = BigInt(20191123);

  before(async function() {
    oracleContractFactory = await starknet.getContractFactory("Oracle");
    clientContractFactory = await starknet.getContractFactory("Client");
  });

  it("Test", async function() {
    console.log("Started deployment");

    const oracleContract: StarknetContract = await oracleContractFactory.deploy();
    console.log("Deployed at", oracleContract.address);
    oracleAddress = BigInt(oracleContract.address);
    const clientContract: StarknetContract = await clientContractFactory.deploy();
    console.log("Deployed at", clientContract.address);
    clientAddress = BigInt(clientContract.address);
    
    // Make a request 
    await clientContract.invoke("request_basketball_results", { oracle_address: oracleAddress, team: team1Int, date: matchDate});

    // Consume the request
    await oracleContract.invoke("callback_client", {client_address: clientAddress, response_data: [BigInt(0),team1Int,BigInt(116),team2Int,BigInt(97),matchDate]});

    const { result: res } =await clientContract.call("get_result");
    
    expect(res.game).to.deep.equal(BigInt(0));
    expect(res.team1).to.deep.equal(team1Int);
    expect(res.team1_score).to.deep.equal(team1Score);
    expect(res.team2).to.deep.equal(team2Int);
    expect(res.team2_score).to.deep.equal(team2Score);
    expect(res.date).to.deep.equal(matchDate);
  });
});