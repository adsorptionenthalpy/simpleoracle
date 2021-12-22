// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @custom:security-contact brian@valts.com
contract Valts1155 is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

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

    address owner;
    int oraclecount;
    address[] listoracles;
    address token;

    event token_transferred(address account, uint256 amount, bytes32 trxid);
    event oracle_unregistered(address account);
    event oracle_registered(address account);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address[] memory oraclelist) initializer {

      owner = msg.sender;
      oraclecount = 3;
      require(oraclelist.length == 3, "Cannot deploy without 3 oracles");

     for (uint8 o = 0; o < 3; o++ ) {
         require(oraclelist[o] != owner, "Contract owner cannot be oracle");
         require(!oracles[oraclelist[o]].active, "oracle already entered");
         require(oraclelist[o] != address(0), "Invalid account");
         oracles[oraclelist[o]].active = true;
         listoracles.push(oraclelist[o]);
       }
    }

    function initialize() initializer public {
        __ERC1155_init("httpa://nft.valts.io/api/item/{id}.json");
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) oracleOnly {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) oracleOnly {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // The following are added to support oracle operations

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

    function mintnfts(address account, uint256 amount, bytes32 trxid) external oracleOnly whenNotPaused{
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
         // mint action
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

}
