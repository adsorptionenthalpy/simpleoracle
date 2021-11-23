// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Tokenoracle {

    struct oracle {
        bool active;
    }

    struct pending {
      mapping (address => bool) approved;
      int approvals;
      address account;
      uint256 amount;
    }

    mapping ( address => oracle) oracles;
    mapping ( bytes32 => pending) approvals; // bytes32 hash can be any trx id

    bool paused;
    address owner;
    int oraclecount;
    address[] listoracles;
    address token;

    constructor(address[] memory oraclelist, address _token) {

       paused = false;
       owner = msg.sender;
       oraclecount = 3;
       token = _token;
       require(oraclelist.length == 3, "Cannot deploy without 3 oracles");

      for (uint8 o = 0; o < 3; o++ ) {
          require(oraclelist[o] != owner, "Contract owner cannot be oracle");
          require(!oracles[oraclelist[o]].active, "oracle already entered");
          require(oraclelist[o] != address(0), "Invalid account");
          oracles[oraclelist[o]].active = true;
          listoracles.push(oraclelist[o]);
        }

    } //constructor

    event token_transferred(address account, uint256 amount, bytes32 trxid);
    event oracle_unregistered(address account);
    event oracle_registered(address account);


    modifier ownerOnly {
      require(msg.sender == owner,
         "Only a registered token oracle may call this action.");
      _;
    }

    modifier oracleOnly {
      require(oracles[msg.sender].active,
         "Only a registered token oracle may call this action.");
      _;
    }

    modifier whenNotPaused {
      require(!paused,
         "Oracle contract must not be paused.");
      _;
    }


    modifier whenPaused {
      require(paused,
         "Oracle contract must be paused");
      _;
    }

    function pause() external oracleOnly whenNotPaused {
      paused = true;
    }

    function unpause() external ownerOnly whenPaused {
      paused = false;
    }


    function transfertoken(address account, uint256 amount, bytes32 trxid) external oracleOnly whenNotPaused{
      require(amount >= 1, "1 minimum");
      require(trxid.length > 0, "Invalid trxid");
      require(account != address(0), "Invalid account");
      require(oraclecount >= 3, "Oracles must be 3 or greater");
      bytes32 obthash = keccak256(bytes(abi.encode(trxid)));
      if (approvals[obthash].approvals < oraclecount) {
        require(!approvals[obthash].approved[msg.sender], "oracle has already approved this trxid");
        approvals[obthash].approvals++;
        approvals[obthash].approved[msg.sender] = true;
      }
      if (approvals[obthash].approvals == 1) {
        approvals[obthash].account = account;
        approvals[obthash].amount = amount;
      }
      if (approvals[obthash].approvals > 1) {
        require(approvals[obthash].account == account, "recipient account does not match prior approvals");
        require(approvals[obthash].amount == amount, "amount does not match prior approvals");
      }
      if (approvals[obthash].approvals == oraclecount) {
       require(approvals[obthash].approved[msg.sender], "An approving oracle must execute transfer");
         IERC20(token).transfer(account, amount);
         emit token_transferred(account, amount, trxid);
        delete approvals[obthash];
      }

    }

    function getOracle(address account) external view returns (bool) {
      require(account != address(0), "Invalid address");
      return (oracles[account].active);
    }

    function getOracles() external view returns(address[] memory) {
      return listoracles;
     }

    function addoracle(address account) external ownerOnly {
      require(!oracles[account].active, "Oracle already registered");
      listoracles.push(account);
      oracles[account].active = true;
      emit oracle_registered(account);
    }

    function remoracle(address account) external ownerOnly {
      require(oracles[account].active, "Oracle must be registered");
      oracles[account].active = false;
      for (uint32 o = 0; o < listoracles.length - 1; o++) {
        if (listoracles[o] == account) {
          listoracles[o] = listoracles[listoracles.length - 1];
          listoracles.pop();
          break;
        }
      }
      emit oracle_unregistered(account);
    }

    function changetoken(address _token) external ownerOnly {
      token = _token;
    }


}
