import "@shardlabs/starknet-hardhat-plugin";

module.exports = {
    cairo: {
      //version: "0.6.2" // alternatively choose one of the two venv options below
  
      // uses (my-venv) defined by `python -m venv path/to/my-venv`
      // venv: "path/to/my-venv"
      
      // uses the currently active Python environment (hopefully with available Starknet commands!) 
       venv: "active"
    },
    networks: {
      devnet: {
        url: "http://localhost:5000"
      }
    },
    mocha: {
        //starknetNetwork: "devnet"
      starknetNetwork: "alpha"
    }
  };
  