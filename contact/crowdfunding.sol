// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address public owner;
    uint256 public fundingGoal;
    uint256 public totalFundsRaised;
    uint256 public deadline;
    bool public campaignEnded;
    
    mapping(address => uint256) public contributions;
    address[] public contributors;
    
    event ContributionReceived(address contributor, uint256 amount);
    event FundsWithdrawn(address owner, uint256 amount);
    event RefundIssued(address contributor, uint256 amount);
    event DeadlineExtended(uint256 newDeadline);
    event CampaignCancelled();
    
    constructor(uint256 _fundingGoal, uint256 _durationInDays) {
        owner = msg.sender;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        campaignEnded = false;
    }
    
    // Function 1: Contribute to the campaign
    function contribute() public payable {
        require(!campaignEnded, "Campaign has ended");
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value > 0, "Contribution must be greater than 0");
        
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        
        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;
        
        emit ContributionReceived(msg.sender, msg.value);
    }
    
    // Function 2: Withdraw funds if goal is reached
    function withdrawFunds() public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(block.timestamp >= deadline, "Campaign is still active");
        require(totalFundsRaised >= fundingGoal, "Funding goal not reached");
        require(!campaignEnded, "Funds already withdrawn");
        
        campaignEnded = true;
        uint256 amount = address(this).balance;
        
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(owner, amount);
    }
    
    // Function 3: Claim refund if goal is not reached
    function claimRefund() public {
        require(block.timestamp >= deadline, "Campaign is still active");
        require(totalFundsRaised < fundingGoal, "Funding goal was reached");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        
        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Refund failed");
        
        emit RefundIssued(msg.sender, refundAmount);
    }
    
    // Function 4: Extend campaign deadline (only owner)
    function extendDeadline(uint256 _additionalDays) public {
        require(msg.sender == owner, "Only owner can extend deadline");
        require(!campaignEnded, "Campaign has ended");
        require(block.timestamp < deadline, "Campaign deadline has passed");
        require(_additionalDays > 0, "Additional days must be greater than 0");
        
        deadline += (_additionalDays * 1 days);
        
        emit DeadlineExtended(deadline);
    }
    
    // Function 5: Cancel campaign and refund all contributors (only owner)
    function cancelCampaign() public {
        require(msg.sender == owner, "Only owner can cancel campaign");
        require(!campaignEnded, "Campaign has already ended");
        require(block.timestamp < deadline, "Campaign deadline has passed");
        
        campaignEnded = true;
        
        // Refund all contributors
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 refundAmount = contributions[contributor];
            
            if (refundAmount > 0) {
                contributions[contributor] = 0;
                (bool success, ) = payable(contributor).call{value: refundAmount}("");
                require(success, "Refund failed");
                emit RefundIssued(contributor, refundAmount);
            }
        }
        
        emit CampaignCancelled();
    }
    
    // Helper function to check campaign status
    function getCampaignStatus() public view returns (
        uint256 _totalFundsRaised,
        uint256 _fundingGoal,
        uint256 _timeRemaining,
        bool _goalReached,
        bool _isActive
    ) {
        uint256 timeRemaining = block.timestamp >= deadline ? 0 : deadline - block.timestamp;
        return (
            totalFundsRaised,
            fundingGoal,
            timeRemaining,
            totalFundsRaised >= fundingGoal,
            block.timestamp < deadline && !campaignEnded
        );
    }
    
    // Helper function to get all contributors
    function getContributors() public view returns (address[] memory) {
        return contributors;
    }
    
    // Helper function to get total number of contributors
    function getContributorCount() public view returns (uint256) {
        return contributors.length;
    }
}
