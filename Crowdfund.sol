// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Bank {
    address public owner;

    struct BankAccount {
        string acct_name;
        address acct_address;
        uint balance;
    }

    mapping (address => uint) internal balanceOf;
    mapping (address => BankAccount) public user_account;
    BankAccount[] private acct_array;
    BankAccount private acct = user_account[msg.sender];

    event AccountCreated(address sender, string name, BankAccount _acct);
    event Transfer(address sender, address to, uint amount);
    event Withdraw(address sender, uint amount);

    // set owner to deployer of the contract
    constructor () {
        owner = payable(msg.sender);
    }

    // fallback() external payable { }

    receive() external payable { }

    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier notZeroAddress(address addy) {
        require(addy != address(0), "invalid address");
        _;
    }

    // modifier validAddress(address addy) {
    //     require(addy == owner, "not owner");
    //     _;
    // }
    
    // function to create an account
    function createAccount(string calldata _name) external returns (BankAccount memory account) {
        // BankAccount memory acct = user_account[msg.sender];
        require(msg.sender != address(0), "Cant create an account for this address");
        require(acct.acct_address == address(0), "You already have an account");
        // creating the account
        account = BankAccount(_name, msg.sender,0);
        // add it to account array
        acct_array.push(account);
        user_account[msg.sender] = account;
        emit AccountCreated(msg.sender, _name, account);
    }

    // function to deposit
    function deposit(uint _amt) external {
        // BankAccount memory acct = user_account[msg.sender];
        balanceOf[msg.sender] += _amt;
        acct.balance += _amt;
        user_account[msg.sender] = BankAccount(acct.acct_name, msg.sender, balanceOf[msg.sender]);
    }

    // function to transfer to other accounts
    function transfer(address payable to, uint _amt) external payable returns (string memory){
        // BankAccount memory acct = user_account[msg.sender];
        require(acct.balance >= _amt, "insufficient balance");
        acct.balance -= _amt;
        balanceOf[msg.sender] -= _amt;
        user_account[msg.sender] = BankAccount(acct.acct_name, msg.sender, balanceOf[msg.sender]);
        (bool successful, ) = to.call{value: _amt}("");
        require(successful, "not successful");
        emit Transfer(msg.sender, to, _amt);
        return "successful";
    }

    // function to withdraw money from your account
    function withdraw(uint _amt) external returns (string memory) {
        // BankAccount memory acct = user_account[msg.sender];
        require(acct.balance >= _amt, "insufficient balance");
        acct.balance -= _amt;
        balanceOf[msg.sender] -= _amt;
        user_account[msg.sender] = BankAccount(acct.acct_name, msg.sender, balanceOf[msg.sender]);
        // (bool successful, ) = msg.sender.call{value: _amt}("");
        // require(successful, "not successful");
        emit Withdraw(msg.sender, _amt);
        return "successful";
    }

    // function to check balance
    function getBalance() external view returns (uint balance) {
        // BankAccount memory acct = user_account[msg.sender];
        balance = acct.balance;
    }
}
