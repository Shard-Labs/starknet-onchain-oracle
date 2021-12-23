import { expect } from "chai";
import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory } from "hardhat/types/runtime";

describe("Starknet", function () {
  this.timeout(300_000);
  
  const ORACLE_ADDRESS = BigInt("0x00bb15272dfc2acc02a87cebbc342c91bedd1a110ceb3bbe5979495349cd7407");
  const CLIENT_ADDRESS = "0x052ff44f138870e7fea7ba8eabb26fc0d4ac72ea958db77e688e0e0ce1bf24f4";

  let clientContractFactory: StarknetContractFactory;


  const team1Name = "Brooklyn Nets";
  const team1Int = starknet.stringToBigInt(team1Name);
  const team1Score = BigInt(116);

  const team2Name = "Sacramento Kings";
  const team2Int = starknet.stringToBigInt(team2Name);
  const team2Score = BigInt(97);
  
  const matchDate = BigInt(20191123);


  it("Test", async function() {
    console.log("Started deployment");

    clientContractFactory = await starknet.getContractFactory("Client");

    const clientContract: StarknetContract = await clientContractFactory.getContractAt(CLIENT_ADDRESS);
    console.log("Deployed at", clientContract.address);
    
    // Make a request 
    await clientContract.invoke("request_basketball_results", { oracle_address: ORACLE_ADDRESS, team: team1Int, date: matchDate});

    // Wait for server to consume request should Consume the request
    await new Promise(f => setTimeout(f, 200000));
    const { result: res } =await clientContract.call("get_result");
    
    const result = {
      game: parseInt(res.game),
      team1: starknet.bigIntToString(res.team1),
      team1_score: parseInt(res.team1_score),
      team2: starknet.bigIntToString(res.team2),
      team2_score: parseInt(res.team2_score),
      Date: parseInt(res.date).toString().replace(/(\d{4})(\d{2})(\d{2})/g, '$1-$2-$3')
    }
    console.log("RESULT: ");
    console.log(result);
  });
});