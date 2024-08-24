// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Crowdfund {
    address payable public owner;
    struct Campaign {
        uint id;
        string title;
        string description;
        address payable benefactor;
        address owner;
        uint goal;
        uint deadline;
        uint amountRaised;
        bool ended;
    }

    // mapping (uint => Campaign) public campaign;
    Campaign[] public all_campaigns;

    event CampaignCreated(Campaign newcampaign);
    event DonationReceived(uint amt);
    event CampaignEnded();

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    receive() external payable { }

    // function to create campaign
    // goal should be greater than 0
    function createCampaign(
        string memory _title,
        string memory _desc,
        address _benefactor,
        uint _goal,
        uint _duration
    ) external {
        require(_goal > 0, "goal cant be 0");
        require(_duration > block.timestamp, "invalid duration");
        require(_benefactor != address(0), "invalid address");
        Campaign memory newCampaign = Campaign({
            id: all_campaigns.length,
            title: _title,
            description: _desc,
            benefactor: payable(_benefactor),
            owner: msg.sender,
            goal: _goal,
            deadline: block.timestamp + _duration,
            amountRaised: 0,
            ended: false
        });

        all_campaigns.push(newCampaign);

        emit CampaignCreated(newCampaign);
    }

    // function to donate to campaign
    function donate(uint _id, uint _amount) external payable returns (string memory) {
        Campaign memory current_campaign = all_campaigns[_id];
        require(current_campaign.deadline > block.timestamp, "campaign ended");
        require(_amount > 0, "amount cant be 0");
        current_campaign.amountRaised += _amount;
        all_campaigns[_id] = current_campaign;
        (bool ok, ) = payable(address(this)).call{value: _amount}("");
        require(ok, "call not successful");

        emit DonationReceived(_amount);
        return "donation successful";
    }

    // function to end campaign and xfer to benefactor
    function endCampaign(uint _id) external payable {
        Campaign memory target_campaign = all_campaigns[_id];
        require(target_campaign.deadline <= block.timestamp, "campaign still ongoing");
        (bool ok, ) = target_campaign.benefactor.call{value: target_campaign.goal}("");
        require(ok, "call not successful");
        target_campaign.ended = true;

        emit CampaignEnded();

        toOwner(target_campaign);
    }

    // function to transfer remaining amoun to owner
    function toOwner(Campaign memory _campaign) public payable onlyOwner {
        if (_campaign.ended && _campaign.amountRaised > _campaign.goal) {
            uint deficit = _campaign.amountRaised - _campaign.goal;
            (bool ok, ) = owner.call{value: deficit}("");
            require(ok, "call not successful");
        }
    }
}
