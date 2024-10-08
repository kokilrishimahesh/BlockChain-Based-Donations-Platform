// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface DonationsInterface {
    function getCampaignDetails(uint256 campaignId)
        external
        view
        returns (
            string memory,
            string memory,
            address,
            uint256,
            uint256,
            string memory,
            address[] memory
        );
}

contract ProfileManager {
    // Org says that the account belongs to an organisation
    enum Role {
        Admin,
        Org,
        User
    }

    struct Owner {
        address ownerAddress;
        Role role;
        uint256 creationDate;
        string name;
        string profileImage;
        string description;
        uint256[] campaignIds; // Change the type to uint256[] memory
    }

    mapping(address => Owner) public owners; // Mapping of owner addresses to Owner profiles

    address public donationsContract; // Address of the Donations contract
    DonationsInterface donationsInstance;

    // Modifier to restrict access to the Donations contract
    modifier onlyDonationsContract() {
        require(
            msg.sender == donationsContract,
            "Only Donations contract can call this function."
        );
        _;
    }

    // Constructor to set the Donations contract address
    constructor(address _donationsContract) {
        donationsContract = _donationsContract;
        donationsInstance = DonationsInterface(_donationsContract);
    }

    // Function to create an owner profile
    function createOwnerProfile(
        Role _role,
        string memory _name,
        string memory _profileImage,
        string memory _description
    ) public {
        require(
            owners[msg.sender].ownerAddress == address(0),
            "Owner profile already exists."
        );

        uint256[] memory myDynamicArray;

        owners[msg.sender] = Owner({
            ownerAddress: msg.sender,
            role: _role,
            creationDate: block.timestamp,
            name: _name,
            profileImage: _profileImage,
            description: _description,
            campaignIds: myDynamicArray
        });
    }

    // Check if the sender is the owner of the profile
    function isProfileOwner(address _user)
        public
        view
        onlyDonationsContract
        returns (bool)
    {
        Owner memory owner = owners[_user];

        require(owner.ownerAddress != address(0), "Profile does not exist"); // Ensure the profile exists

        return owner.ownerAddress == _user; // if it matches return true or else false
    }

    function isProfileActive(address _user)
        public
        view
        onlyDonationsContract
        returns (bool)
    {
        Owner memory owner = owners[_user]; // Retrieve the owner using the user address as the key

        return owner.ownerAddress != address(0);
    }

    // Function to update owner profile details
    // address, date, role are immutable
    function updateOwnerProfile(
        string memory _name,
        string memory _profileImage,
        string memory _description
    ) public {
        Owner storage owner = owners[msg.sender];
        require(
            owner.ownerAddress != address(0),
            "Owner profile does not exist."
        );

        // address(0) is a special address in Ethereum that represents a non-existent or uninitialized address.
        // It is often used to signify "no address" or "null."
        owner.name = _name;
        owner.profileImage = _profileImage;
        owner.description = _description;
    }

    // Function to retrieve owner details
    function getOwnerDetails(address _ownerAddress)
        public
        view
        returns (Owner memory)
    {
        return owners[_ownerAddress];
    }

    // Function to add a campaign ID to an owner's profile (accessible only by Donations contract)
    function addCampaign(
        address _ownerAddress,
        uint256 _campaignId // Pass the campaign ID from Donations contract
    ) public onlyDonationsContract {
        require(
            owners[_ownerAddress].ownerAddress != address(0),
            "Owner profile does not exist."
        );

        owners[_ownerAddress].campaignIds.push(_campaignId); // Store the campaignId
    }

    // Function to get campaign details for an owner from the Donations contract
    function getCampaigns(address _ownerAddress)
        public
        view
        returns (
            string[] memory titles,
            string[] memory descriptions,
            address[] memory creators,
            uint256[] memory targets,
            uint256[] memory deadlines,
            string[] memory statuses,
            address[][] memory contributors
        )
    {
        uint256[] memory campaignIds = owners[_ownerAddress].campaignIds;
        titles = new string[](campaignIds.length);
        descriptions = new string[](campaignIds.length);
        creators = new address[](campaignIds.length);
        targets = new uint256[](campaignIds.length);
        deadlines = new uint256[](campaignIds.length);
        statuses = new string[](campaignIds.length);
        contributors = new address[][](campaignIds.length);

        for (uint256 i = 0; i < campaignIds.length; i++) {
            (
                titles[i],
                descriptions[i],
                creators[i],
                targets[i],
                deadlines[i],
                statuses[i],
                contributors[i]
            ) = donationsInstance.getCampaignDetails(campaignIds[i]);
        }
    }

    // Function to get the role of an owner
    function getOwnerRole(address _ownerAddress) public view returns (Role) {
        return owners[_ownerAddress].role;
    }
}
