// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Donation {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 amountCollected;
        address[] donators;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public donations; // Campaign ID to donator address to amount
    mapping(uint256 => bool) public campaignExists;

    uint256 public campaignCount = 0;

    // Function to create a new campaign
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _target
    ) public {
        campaignCount++;
        Campaign storage campaign = campaigns[campaignCount];

        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.amountCollected = 0;
        campaign.owner = msg.sender;

        campaignExists[campaignCount] = true;
    }

    // Function to donate to a campaign
    function donate(uint256 _campaignId) public payable {
        require(campaignExists[_campaignId], "Campaign does not exist");
        require(msg.value > 0, "Donation must be greater than 0");

        donations[_campaignId][msg.sender] += msg.value;
        campaigns[_campaignId].amountCollected += msg.value;
        campaigns[_campaignId].donators.push(msg.sender);
    }

    // Function to get campaign details by ID
    function getCampaign(uint256 _campaignId)
        public
        view
        returns (
            address owner,
            string memory title,
            string memory description,
            uint256 target,
            uint256 amountCollected,
            address[] memory donators
        )
    {
        require(campaignExists[_campaignId], "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        
        return (
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.target,
            campaign.amountCollected,
            campaign.donators
        );
    }

    // Function to get total donations by an address for a specific campaign
    function getDonationAmount(uint256 _campaignId, address _donator)
        public
        view
        returns (uint256)
    {
        return donations[_campaignId][_donator];
    }

    function getDonators(uint256 _campaignId)
        public
        view
        returns (address[] memory)
    {
        Campaign storage campaign = campaigns[_campaignId];
        return campaign.donators;
    }

    // Function to receive Ether (for example, donations)
    receive() external payable {}
}
