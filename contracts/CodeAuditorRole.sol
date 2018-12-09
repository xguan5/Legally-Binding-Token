pragma solidity ^0.4.24;

import "node_modules/openzeppelin-solidity/contracts/access/Roles.sol";
import "./GranterRole.sol";

contract CodeAuditorRole is GranterRole {
  using Roles for Roles.Role;

  event CodeAuditorAdded(address indexed account);
  event CodeAuditorRemoved(address indexed account);

  Roles.Role private codeauditors;

  // constructor() public {
  //   //_addCodeAuditor(msg.sender);
  // }

  modifier onlyCodeAuditor() {
    require(isCodeAuditor(msg.sender));
    _;
  }

  function isCodeAuditor(address account) public view returns (bool) {
    return codeauditors.has(account);
  }

  function addCodeAuditor(address account) public onlyGranter {
    _addCodeAuditor(account);
  }

  function renounceCodeAuditor(address account) public onlyGranter {
    _removeCodeAuditor(account);
  }

  function _addCodeAuditor(address account) internal {
    codeauditors.add(account);
    emit CodeAuditorAdded(account);
  }

  function _removeCodeAuditor(address account) internal {
    codeauditors.remove(account);
    emit CodeAuditorRemoved(account);
  }
}
