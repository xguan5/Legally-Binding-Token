pragma solidity ^0.4.24;

import "node_modules/openzeppelin-solidity/contracts/access/Roles.sol";
import "./GranterRole.sol";

contract BeneficiaryRole is GranterRole{
  using Roles for Roles.Role;

  event BeneficiaryAdded(address indexed account);
  event BeneficiaryRemoved(address indexed account);

  Roles.Role private beneficiarys;

  // constructor() public {
  //   //_addBeneficiary(msg.sender);
  // }

  modifier onlyBeneficiary() {
    require(isBeneficiary(msg.sender));
    _;
  }

  function isBeneficiary(address account) public view returns (bool) {
    return beneficiarys.has(account);
  }

  function addBeneficiary(address account) public onlyGranter {
    _addBeneficiary(account);
  }

  function renounceBeneficiary(address account) public onlyGranter {
    _removeBeneficiary(account);
  }

  function _addBeneficiary(address account) internal {
    beneficiarys.add(account);
    emit BeneficiaryAdded(account);
  }

  function _removeBeneficiary(address account) internal {
    beneficiarys.remove(account);
    emit BeneficiaryRemoved(account);
  }
}
