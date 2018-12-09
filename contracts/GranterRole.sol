pragma solidity ^0.4.24;

import "node_modules/openzeppelin-solidity/contracts/access/Roles.sol";

contract GranterRole {
  using Roles for Roles.Role;

  event GranterAdded(address indexed account);
  event GranterRemoved(address indexed account);

  Roles.Role private granters;

  constructor() public {
    _addGranter(msg.sender);
  }

  modifier onlyGranter() {
    require(isGranter(msg.sender));
    _;
  }

  function isGranter(address account) public view returns (bool) {
    return granters.has(account);
  }

  function addGranter(address account) public onlyGranter {
    _addGranter(account);
  }

  function renounceGranter(address account) public onlyGranter {
    _removeGranter(account);
  }

  function _addGranter(address account) internal {
    granters.add(account);
    emit GranterAdded(account);
  }

  function _removeGranter(address account) internal {
    granters.remove(account);
    emit GranterRemoved(account);
  }
}
