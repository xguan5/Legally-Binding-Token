pragma solidity ^0.4.24;

import "./LawyerRole.sol";
import "./GranterRole.sol";
import "./CodeAuditorRole.sol";
import "./BeneficiaryRole.sol";
//import "node_modules/_openzeppelin-solidity@2.0.0@openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
//import "node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Document is GranterRole, LawyerRole, CodeAuditorRole, BeneficiaryRole {


	struct DocStruct {
		address granter;
		address lawyer;
		address codeAudit;
		address beneficiary;
		bool granterSigned;
		bool lawyerSigned;
		bool codeAuditSigned;
		bool beneficiarySigned;
		bool submitted;
		uint index;
	}

	bytes32[] docIndex; //list of doc keys (docHash)


	//use docHash as key to map to DocStruct
	mapping (bytes32 => DocStruct) public DocStructs;

	event DocumentAdd(bytes32 indexed docHash);
	event DocumentSubmit(bytes32 indexed docHash);
	event LawyerRevocation(address indexed sender, bytes32 indexed docHash);
	event BeneficiaryRevocation(address indexed sender, bytes32 indexed docHash);
	event GranterRevocation(address indexed sender, bytes32 indexed docHash);
	event CodeAuditRevocation(address indexed sender, bytes32 indexed docHash);
	event LawyerConfirmation(address indexed sender, bytes32 indexed docHash);
	event BeneficiaryConfirmation(address indexed sender, bytes32 indexed docHash);
	event GranterConfirmation(address indexed sender, bytes32 indexed docHash);
	event CodeAuditConfirmation(address indexed sender, bytes32 indexed docHash);

	/**
   * @dev Throws if called by any account other than the owner.
   */
	modifier allSigned(bytes32 docHash) {
		require(DocStructs[docHash].lawyerSigned,"Lawyer has not signed yet");
		require(DocStructs[docHash].codeAuditSigned,"Code Auditor has not signed yet");
		require(DocStructs[docHash].granterSigned,"Granter has not signed yet");
		require(DocStructs[docHash].beneficiarySigned,"Beneficiary has not signed yet");
		_;
	}

	modifier preAuthorized(address granter, address lawyer, address codeAudit, address beneficiary) {
		require(isGranter(granter),"Granter address is not recognized as granter");
		require(isCodeAuditor(codeAudit),"Code Auditor address is not recognized as code auditor");
		require(isLawyer(lawyer),"Lawyer address is not recognized as lawyer");
		require(isBeneficiary(beneficiary),"Beneficiary address is not recognized as beneficiary");
		_;
	}

	//owner发起上传文件请求，confirm it, 将文件的ipfs hash发给required parties
	//@param docHash is the digest. JS need a function to separate out digest from the ipfs hash
	function addDocument(bytes32 docHash, address _granter, address _lawyer, address _codeAudit, address _beneficiary) public preAuthorized(_granter,_lawyer,_codeAudit,_beneficiary) onlyGranter returns (bool success) {
		//need to check if document doesnt exist yet
		require(!isDoc(docHash),"Document already exist");
		//require none of the four address are the same
		require(compAddress(_beneficiary, _lawyer,_codeAudit,_granter),"The four roles must have different address");

		//create a new docStruct
		DocStructs[docHash] = DocStruct(_granter,_lawyer,_codeAudit,_beneficiary,false,false,false,false,false,docIndex.length);

		DocStructs[docHash].granterSigned = true;
		emit GranterConfirmation(msg.sender, docHash);
		emit DocumentAdd(docHash);
		return true;
	}

	//owner(Granter) add a new document hash, needs confirmation from all requiredparties
	function submitDocument(bytes32 docHash) allSigned(docHash) public returns (bool success) {
		
		//need to check if document doesnt exist yet
		require(!isDoc(docHash),"Document already exist");
		require(msg.sender == DocStructs[docHash].granter);

		docIndex.push(docHash);
		DocStructs[docHash].submitted = true;
		emit DocumentSubmit(docHash);
		return true;
	}

	//relevant party review and confirm
	function confirmDocument(bytes32 docHash) public returns (bool success) {
		require(DocStructs[docHash].granterSigned);

		if (DocStructs[docHash].lawyer == msg.sender){
			DocStructs[docHash].lawyerSigned = true;
			emit LawyerConfirmation(msg.sender, docHash);
		} else if (DocStructs[docHash].codeAudit == msg.sender){
			DocStructs[docHash].codeAuditSigned = true;
			emit CodeAuditConfirmation(msg.sender, docHash);
		} else if (DocStructs[docHash].beneficiary == msg.sender){
			DocStructs[docHash].beneficiarySigned = true;
			emit BeneficiaryConfirmation(msg.sender, docHash);
		} 

		return true;

	}

	function revokeConfirmation(bytes32 docHash) public returns (bool success) {

		//this has to be done before document is submitted
		require(!DocStructs[docHash].submitted,"Document has already been submitted, cannot revoke confirmation");

		if (DocStructs[docHash].lawyer == msg.sender){
			DocStructs[docHash].lawyerSigned = false;
			emit LawyerRevocation(msg.sender, docHash);
		} else if (DocStructs[docHash].codeAudit == msg.sender){
			DocStructs[docHash].codeAuditSigned = false;
			emit CodeAuditRevocation(msg.sender, docHash);
		} else if (DocStructs[docHash].beneficiary == msg.sender){
			DocStructs[docHash].beneficiarySigned = false;
			emit BeneficiaryRevocation(msg.sender, docHash);
		} else if (DocStructs[docHash].granter == msg.sender){
			DocStructs[docHash].granterSigned = false;
			emit GranterRevocation(msg.sender, docHash);
		}
		
		return true;
	}

	function isDoc(bytes32 docHash) public constant returns (bool isIndeed) {
		//if docIndex array is empty, this document doesnt exist
		if (docIndex.length == 0) return false;
		//get the index of the signer to look up its address
		return(docIndex[DocStructs[docHash].index] == docHash);
	}

	//returns all document hashes
	function getAllDocument() public view returns (bytes32[] docHashes) {
		bytes32[] return_array;
		for(uint i = 0; i < docIndex.length; i++) {
			return_array.push(docIndex[i]);
		}

		return return_array;
	}

	function countAllDocument() public view returns (uint count) {
		return docIndex.length;
	}

	function getDocAtIndex(uint index) public constant returns(bytes32 docHash) {
	  return docIndex[index];
	}

	function getDocStatus(bytes32 docHash) public constant returns(address granter, address lawyer, address codeAudit, address beneficiary, bool granterSigned, bool lawyerSigned, bool codeAuditSigned, bool beneficiarySigned) {
		DocStruct memory d = DocStructs[docHash];
		return (d.granter, d.lawyer, d.codeAudit, d.beneficiary, d.granterSigned, d.lawyerSigned, d.codeAuditSigned, d.beneficiarySigned);
	}

	//make sure none of the 4 address are the same
	function compAddress(address _a, address _b, address _c, address _d) internal pure returns (bool success) {
		if((_a == _b)||(_a == _c)||(_a==_d)||(_b==_c)||(_b==_d)||(_c==_d)) {
			//there is match
			return false;
		}
		//none are the same
		return true;
	}

}
