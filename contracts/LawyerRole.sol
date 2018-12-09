pragma solidity ^0.4.24;

import "node_modules/openzeppelin-solidity/contracts/access/Roles.sol";
import "./GranterRole.sol";

contract LawyerRole is GranterRole {
  using Roles for Roles.Role;

  event LawyerAdded(address indexed account);
  event LawyerRemoved(address indexed account);

  Roles.Role private lawyers;

  constructor() public onlyGranter {
    //_addLawyer(msg.sender);
  }

  modifier onlyLawyer() {
    require(isLawyer(msg.sender));
    _;
  }

  function isLawyer(address account) public view returns (bool) {
    return lawyers.has(account);
  }

  function addLawyer(address account) public onlyGranter {
    _addLawyer(account);
  }

  function renounceLawyer(address account) public onlyGranter {
    _removeLawyer(account);
  }

  function _addLawyer(address account) internal {
    lawyers.add(account);
    emit LawyerAdded(account);
  }

  function _removeLawyer(address account) internal {
    lawyers.remove(account);
    emit LawyerRemoved(account);
  }
}
