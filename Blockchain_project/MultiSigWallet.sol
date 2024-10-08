// SPDX-License-Identifier: Apache-1.1
pragma solidity ^0.8.9;

import "./ProfileManager.sol"; // Assuming ProfileManager is a separate contract that manages profiles
import "./Donation.sol";

contract MultiSigWallet {
    address[] public signers; // Array of signers
    mapping(address => bool) public isSigner; // Mapping to check if an address is a signer
    uint256 public requiredApprovals; // Required approvals to execute a transaction
    address public donationContract; // Address of the Donation contract

    struct Transaction {
        address to; // Address to send funds
        uint256 amount; // Amount to send
        bool executed; // Status of execution
        uint256 approvalCount; // Number of approvals received
        mapping(address => bool) approved; // Mapping of approvals
        uint256 signerIndex; // Index of the signer who created the transaction
    }

    Transaction[] public transactions; // Array of transactions

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    modifier onlyDonationContract() {
        require(
            msg.sender == donationContract,
            "Only Donations contract can call this function."
        );
        _;
    }

    constructor(
        address[] memory _signers,
        uint256 _requiredApprovals,
        address _donationContract
    ) {
        require(_signers.length > 0, "At least one signer required");
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _signers.length,
            "Invalid number of approvals"
        );

        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "Invalid signer");
            isSigner[_signers[i]] = true;
        }
        signers = _signers;
        requiredApprovals = _requiredApprovals;
        donationContract = _donationContract; // Store the donation contract address
    }

    // Function to create a transaction (restricted to Donation contract)
    function createTransaction(address _to, uint256 _amount)
        public
        onlyDonationContract
    {
        transactions.push();
        Transaction storage transaction = transactions[transactions.length - 1];
        transaction.to = _to;
        transaction.amount = _amount;
        transaction.executed = false;
        transaction.approvalCount = 0;
        transaction.signerIndex = 0; // Initialize as needed, or set appropriately
    }

    function approveTransaction(uint256 _transactionId) public onlySigner {
        require(_transactionId < transactions.length, "Invalid transaction ID");

        Transaction storage transaction = transactions[_transactionId];

        // Check if the signer has already approved
        require(
            !transaction.approved[msg.sender],
            "Transaction already approved by this signer"
        );

        // Check if the transaction is already executed
        require(!transaction.executed, "Transaction already executed");

        // Approve the transaction
        transaction.approved[msg.sender] = true;
        transaction.approvalCount++;

        // Execute if approvals are enough
        if (transaction.approvalCount >= requiredApprovals) {
            executeTransaction(_transactionId);
        }
    }

    function executeTransaction(uint256 _transactionId) internal {
        Transaction storage transaction = transactions[_transactionId];

        // Check that enough approvals have been received
        require(
            transaction.approvalCount >= requiredApprovals,
            "Not enough approvals"
        );

        // Check that the transaction hasn't already been executed
        require(!transaction.executed, "Transaction already executed");

        // Check if the donations contract has sufficient balance
        require(
            address(donationContract).balance >= transaction.amount,
            "Insufficient donations contract balance"
        );

        // Execute the transaction and mark it as executed
        transaction.executed = true;

        // Transfer the funds from the donations account to the specified address
        (bool success, ) = payable(transaction.to).call{ value: transaction.amount }(""); // Transfer the funds
        require(success, "Transfer failed"); // Ensure the transfer was successful
    }

    // Function to view all transactions
    function getAllTransactions()
        public
        view
        returns (
            address[] memory to,
            uint256[] memory amounts,
            bool[] memory executed,
            uint256[] memory approvalCounts
        )
    {
        uint256 transactionCount = transactions.length;

        to = new address[](transactionCount);
        amounts = new uint256[](transactionCount);
        executed = new bool[](transactionCount);
        approvalCounts = new uint256[](transactionCount);

        for (uint256 i = 0; i < transactionCount; i++) {
            Transaction storage txn = transactions[i];
            to[i] = txn.to;
            amounts[i] = txn.amount;
            executed[i] = txn.executed;
            approvalCounts[i] = txn.approvalCount;
        }
    }

    // Function to view unexecuted transactions
    function getUnexecutedTransactions()
        public
        view
        returns (
            address[] memory to,
            uint256[] memory amounts,
            uint256[] memory approvalCounts
        )
    {
        uint256 unexecutedCount = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (!transactions[i].executed) {
                unexecutedCount++;
            }
        }

        to = new address[](unexecutedCount);
        amounts = new uint256[](unexecutedCount);
        approvalCounts = new uint256[](unexecutedCount);

        uint256 index = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (!transactions[i].executed) {
                Transaction storage txn = transactions[i];
                to[index] = txn.to;
                amounts[index] = txn.amount;
                approvalCounts[index] = txn.approvalCount;
                index++;
            }
        }
    }

    // Function to receive Ether
    receive() external payable {}
}
