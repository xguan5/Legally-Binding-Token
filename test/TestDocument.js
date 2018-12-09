/* eslint-disable no-undef */
const assert = require('chai').assert; // use Chai Assertion Library
const expect = require('chai').expect;
const ganache = require('ganache-cli'); // use ganache-cli with ethereum-bridge for Oraclize
const { inLogs } = require('openzeppelin-solidity/test/helpers/expectEvent')


// Configure web3 1.0.0 instead of the default version with Truffle
const Web3 = require('web3')
const provider = ganache.provider()
const web3 = new Web3(provider)

var Document = artifacts.require("./Document.sol");
var Lawyer = artifacts.require("./LawyerRole.sol");
var Granter = artifacts.require("./GranterRole.sol");
var CodeAuditor = artifacts.require("./CodeAuditorRole.sol");
var Beneficiary = artifacts.require("./BeneficiaryRole.sol");


contract('GranterRole', function(accounts){

	var granter1 = accounts[0];
	var granter2 = accounts[1];

	// beforeEach('setup contract for each test', async function () {
 //      granter = await Granter.new();
 //  	})

  	it('after initialize granter1 should be in granter list', async function() {
  		granter = await Granter.new({from: granter1});
  		assert.equal(await granter.isGranter(granter1), true);
  	})

  	it('add a granter', async function(){
  		await granter.addGranter(granter2);
  		assert.equal(await granter.isGranter(granter2),true);
  	})

  	it('renounce a granter', async function(){
  		await granter.renounceGranter(granter2,{from:granter1});
  		assert.equal(await granter.isGranter(granter2),false);
  	})
})

contract('LawyerRole', function(accounts){
	var granter1 = accounts[0];
	var granter2 = accounts[1];
	
	var lawyer1 = accounts[2];
	var lawyer2 = accounts[3];


  	it('after initialize lawyer1 should not be in lawyer list', async function() {
  		lawyer = await Lawyer.new({from: granter1});
  		assert.equal(await lawyer.isLawyer(lawyer1), false);
  	})

	it('add a lawyer', async function(){
		await lawyer.addLawyer(lawyer1,{from: granter1});
		assert.equal(await lawyer.isLawyer(lawyer1),true);
	})

  	it('renounce a lawyer', async function(){
  		await lawyer.renounceLawyer(lawyer1,{from:granter1});
  		assert.equal(await lawyer.isLawyer(lawyer1),false);
  	})

  	it('granter2 should not have authority', async function(){
  		try {
  			await lawyer.addLawyer(lawyer2,{from: granter2});
  		} catch (e) {
  			console.log(e);
  		}
  	})
})

contract('BeneficiaryRole', function(accounts){
	var granter1 = accounts[0];
	var granter2 = accounts[1];
	
	var beneficiary1 = accounts[4];
	var beneficiary2 = accounts[5];


  	it('after initialize beneficiary1 should not be in beneficiary list', async function() {
  		beneficiary = await Beneficiary.new({from: granter1});
  		assert.equal(await beneficiary.isBeneficiary(beneficiary1), false);
  	})

	it('add a beneficiary', async function(){
		await beneficiary.addBeneficiary(beneficiary1,{from: granter1});
		assert.equal(await beneficiary.isBeneficiary(beneficiary1),true);
	})

  	it('renounce a beneficiary', async function(){
  		await beneficiary.renounceBeneficiary(beneficiary1,{from:granter1});
  		assert.equal(await beneficiary.isBeneficiary(beneficiary1),false);
  	})

})

contract('CodeAuditorRole', function(accounts){
	var granter1 = accounts[0];
	var granter2 = accounts[1];
	
	var codeAuditor1 = accounts[6];
	var codeAuditor2 = accounts[7];


	it('after initialize codeAuditor1 should not be in code auditor list', async function() {
		codeAuditor = await CodeAuditor.new({from: granter1});
		assert.equal(await codeAuditor.isCodeAuditor(codeAuditor1), false);
	})

	it('add a code auditor', async function(){
		await codeAuditor.addCodeAuditor(codeAuditor1,{from: granter1});
		assert.equal(await codeAuditor.isCodeAuditor(codeAuditor1),true);
	})

  	it('renounce a code auditor', async function(){
  		await codeAuditor.renounceCodeAuditor(codeAuditor1,{from: granter1});
 		assert.equal(await codeAuditor.isCodeAuditor(codeAuditor1),false);
  	})

})


contract('Document', function(accounts) {

	var granter1 = accounts[0];
	var lawyer1 = accounts[2];
  var lawyer2 = accounts[3];
  var beneficiary1 = accounts[4];
	var codeAuditor1 = accounts[6];
	var docHash1 = '0x1111111111111111111111111111111111111111111111111111111111111111';
	var docHash2 = '0x2222222222222222222222222222222222222222222222222222222222222222';

	it('after initialize doc list should be empty', async function() {
  		doc = await Document.new({from: granter1});
  		assert.equal(await doc.countAllDocument(), 0);
  	})

	it('authroize all relevent parties', async function(){
		//await doc.addGranter(granter1,{from:granter1});
		assert.equal(await doc.isGranter(granter1), true);
		await doc.addLawyer(lawyer1,{from:granter1});
		assert.equal(await doc.isLawyer(lawyer1),true);
		await doc.addCodeAuditor(codeAuditor1,{from: granter1});
		assert.equal(await doc.isCodeAuditor(codeAuditor1),true);
		await doc.addBeneficiary(beneficiary1,{from: granter1});
		assert.equal(await doc.isBeneficiary(beneficiary1),true);
	})

	it('add a document all address are different', async function(){
		const { logs } = await doc.addDocument(docHash1, granter1,lawyer1,codeAuditor1,beneficiary1,{from:granter1});
		
    const event = logs.find(e=>e.event == 'DocumentAdd');
    //console.log(event);
    expect(event).to.exist;
    event.args.docHash.should.eq(docHash1);
    
  })

	it('lawyer confirm a document', async function(){
		const { logs } = await doc.confirmDocument(docHash1, {from:lawyer1});

    const event = logs.find(e=>e.event == 'LawyerConfirmation');
    //console.log(event);
    expect(event).to.exist;
    event.args.sender.should.eq(lawyer1);
    event.args.docHash.should.eq(docHash1);
    //event.args.sender.should.not.eq(lawyer2);
		
	})

  it('beneficiary confirm a document', async function(){
    const { logs } = await doc.confirmDocument(docHash1, {from:beneficiary1});

    const event = logs.find(e=>e.event == 'BeneficiaryConfirmation');
    //console.log(event);
    expect(event).to.exist;
    event.args.sender.should.eq(beneficiary1);
    event.args.docHash.should.eq(docHash1);
  })

  it('beneficiary revoke confirmation', async function(){
    const { logs } = await doc.revokeConfirmation(docHash1, {from:beneficiary1});

    const event = logs.find(e=>e.event == 'BeneficiaryRevocation');
    //console.log(event);
    expect(event).to.exist;
    event.args.sender.should.eq(beneficiary1);
    event.args.docHash.should.eq(docHash1);
  })

  it('code auditor confirm a document', async function(){
    const { logs } = await doc.confirmDocument(docHash1, {from: codeAuditor1});

    const event = logs.find(e=>e.event == 'CodeAuditConfirmation');
    //console.log(event);
    expect(event).to.exist;
    event.args.sender.should.eq(codeAuditor1);
    event.args.docHash.should.eq(docHash1);
  })

  it('missing beneficiary confirmation, granter cannot be able to submit the document', async function(){
    try {
      await doc.submitDocument(docHash1, {from: granter1});
    } catch (e) {
      console.log(e);
    }
  })

  it('beneficiary re-confirm a document', async function(){
    const { logs } = await doc.confirmDocument(docHash1, {from:beneficiary1});

    const event = logs.find(e=>e.event == 'BeneficiaryConfirmation');
    //console.log(event);
    expect(event).to.exist;
    event.args.sender.should.eq(beneficiary1);
    event.args.docHash.should.eq(docHash1);
  })

  it('with all the signatures, granter should be able to submit the document', async function(){
    const { logs } = await doc.submitDocument(docHash1, {from: granter1});

    const event = logs.find(e=>e.event == 'DocumentSubmit');
    //console.log(event);
    expect(event).to.exist;
    event.args.docHash.should.eq(docHash1);

    assert.equal(await doc.countAllDocument(),1);
  })

  it('cannot submit same document twice', async function(){
    try {
      await doc.submitDocument(docHash1, {from: granter1});
    } catch (e) {
      console.log(e);
    }
  })

  it('cannot revoke confirmation after document is submitted', async function(){
    try {
      await doc.revokeConfirmation(docHash1, {from: lawyer1});
    } catch (e) {
      console.log(e);
    }
  })

  it('get the status of the submitted document', async function(){
    let result = await doc.getDocStatus(docHash1, {from: granter1});

    assert.equal(granter1,result[0]);
    assert.equal(lawyer1,result[1]);
    assert.equal(codeAuditor1,result[2]);
    assert.equal(beneficiary1,result[3]);
    assert.equal(result[4],true);
    assert.equal(result[5],true);
    assert.equal(result[6],true);
    assert.equal(result[7],true);
    assert.notEqual(result[4],false);

  })

  it('authroize a duplicate lawyer address',async function(){
    await doc.addLawyer(beneficiary1,{from:granter1});
    assert.equal(await doc.isLawyer(beneficiary1),true);
  })
  
  it('add a document not all address are different', async function(){
    
    try {
      await doc.addDocument(docHash2, granter1,beneficiary1,codeAuditor1,beneficiary1,{from:granter1});
    } catch (e) {
      console.log(e);
    }    
    
  })

})
