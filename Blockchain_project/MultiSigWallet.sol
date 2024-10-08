// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MultiSigWallet {
    address[] public signers; // Array of signers
    mapping(address => bool) public isSigner; // Mapping to check if an address is a signer
    uint256 public requiredApprovals; // Required approvals to execute a transaction

    struct Transaction {
        address to; // Address to send funds
        uint256 amount; // Amount to send
        bool executed; // Status of execution
        uint256 approvalCount; // Number of approvals received
        mapping(address => bool) approved; // Mapping of approvals
    }

    Transaction[] public transactions; // Array of transactions

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    constructor(address[] memory _signers, uint256 _requiredApprovals) {
        require(_signers.length > 0, "At least one signer required");
        require(_requiredApprovals > 0 && _requiredApprovals <= _signers.length, "Invalid number of approvals");

        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "Invalid signer");
            isSigner[_signers[i]] = true;
        }
        signers = _signers;
        requiredApprovals = _requiredApprovals;
    }

    // Function to create a transaction
    function createTransaction(address _to, uint256 _amount) public onlySigner {
        transactions.push();
        Transaction storage transaction = transactions[transactions.length - 1];
        transaction.to = _to;
        transaction.amount = _amount;
        transaction.executed = false;
        transaction.approvalCount = 0;
    }

    // Function to approve a transaction
    function approveTransaction(uint256 _transactionId) public onlySigner {
        Transaction storage transaction = transactions[_transactionId];
        require(!transaction.approved[msg.sender], "Transaction already approved");
        require(!transaction.executed, "Transaction already executed");

        transaction.approved[msg.sender] = true;
        transaction.approvalCount++;

        if (transaction.approvalCount >= requiredApprovals) {
            executeTransaction(_transactionId);
        }
    }

    // Function to execute a transaction
    function executeTransaction(uint256 _transactionId) internal {
        Transaction storage transaction = transactions[_transactionId];
        require(transaction.approvalCount >= requiredApprovals, "Not enough approvals");
        require(!transaction.executed, "Transaction already executed");

        transaction.executed = true;
        payable(transaction.to).transfer(transaction.amount); // Send funds
    }

    // Function to receive Ether
    receive() external payable {}
}
