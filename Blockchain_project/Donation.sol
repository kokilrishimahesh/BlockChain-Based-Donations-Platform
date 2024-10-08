// SPDX-License-Identifier: Apache-1.1
pragma solidity ^0.8.9;

import "./MultiSigWallet.sol";
import "./ProfileManager.sol"; // Assuming ProfileManager is a separate contract that manages profiles

contract Donation {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 amountCollected;
        uint256 totalWithdrawn;
        string[] fundUtilization;
        address[] donators;
        MultiSigWallet multiSigWallet; // Separate MultiSig wallet for each campaign
    }

    ProfileManager public profileManager; // Reference to ProfileManager contract
    address public donationContractAddress; // Store this contract's address

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public donations; // Mapping of campaign ID to donator address to amount
    mapping(uint256 => bool) public campaignExists;

    uint256 public campaignCount = 0;

    constructor(address _profileManagerAddress) {
        profileManager = ProfileManager(_profileManagerAddress);
        donationContractAddress = address(this);
        profileManager.setDonationsContract(donationContractAddress);
    }

    // Function to create a campaign associated with a user's profile
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _target,
        address[] memory _signers,
        uint256 _requiredApprovals
    ) public {
        require(
            profileManager.isProfileOwner(msg.sender),
            "Not the profile owner"
        );
        require(_signers.length > 0, "At least one signer required");
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _signers.length,
            "Invalid number of approvals"
        );

        campaignCount++;
        Campaign storage campaign = campaigns[campaignCount];

        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.amountCollected = 0;
        campaign.totalWithdrawn = 0;
        campaign.owner = msg.sender;

        // Create a new MultiSig wallet for this campaign
        campaign.multiSigWallet = new MultiSigWallet(
            _signers,
            _requiredApprovals,
            donationContractAddress // Pass the stored contract address
        );

        campaignExists[campaignCount] = true;
    }

    // Function to donate to a campaign linked with a profile
    function donate(uint256 _campaignId) public payable {
        require(campaignExists[_campaignId], "Campaign does not exist");
        require(
            profileManager.isProfileActive(msg.sender),
            "Profile is not active"
        );
        require(msg.value > 0, "Donation must be greater than 0");

        donations[_campaignId][msg.sender] += msg.value;

        campaigns[_campaignId].amountCollected += msg.value;

        campaigns[_campaignId].donators.push(msg.sender);

    }

    // Function to withdraw funds through multi-sig wallet for a campaign
    function withdrawFunds(
        uint256 _campaignId,
        address _to,
        uint256 _amount
    ) public {
        require(campaignExists[_campaignId], "Campaign does not exist");
        require(
            campaigns[_campaignId].owner == msg.sender,
            "Only campaign owner can withdraw"
        );
        require(
            _amount <=
                campaigns[_campaignId].amountCollected -
                    campaigns[_campaignId].totalWithdrawn,
            "Insufficient funds"
        );

        campaigns[_campaignId].totalWithdrawn += _amount; // Track total withdrawn

        // Use the specific campaign's MultiSig wallet for this withdrawal request
        campaigns[_campaignId].multiSigWallet.createTransaction(_to, _amount);
    }

    // Function to get a campaign by ID
    function getCampaign(uint256 _campaignId)
        public
        view
        returns (Campaign memory)
    {
        require(campaignExists[_campaignId], "Campaign does not exist");
        return campaigns[_campaignId];
    }

    // Function to get donators for a campaign
    function getDonators(uint256 _campaignId)
        public
        view
        returns (address[] memory)
    {
        require(campaignExists[_campaignId], "Campaign does not exist");
        return campaigns[_campaignId].donators;
    }

    // Function for the owner to post fund utilization description
    function postFundUtilization(
        uint256 _campaignId,
        string memory _utilizationDescription
    ) public {
        require(campaignExists[_campaignId], "Campaign does not exist");
        require(
            profileManager.isProfileOwner(msg.sender),
            "Only profile owner can post utilization description"
        );

        campaigns[_campaignId].fundUtilization.push(_utilizationDescription);
    }

    // Function to get details of a campaign
    function getCampaignDetails(uint256 campaignId)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256
        )
    {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.target,
            campaign.amountCollected,
            campaign.totalWithdrawn
        );
    }

    // Function to get MultiSigWallet address for a campaign
    function getMultiSigWalletAddress(uint256 _campaignId)
        public
        view
        returns (address)
    {
        require(campaignExists[_campaignId], "Campaign does not exist");
        return address(campaigns[_campaignId].multiSigWallet);
    }

    // Function to receive Ether (for example, donations)
    receive() external payable {}
}
