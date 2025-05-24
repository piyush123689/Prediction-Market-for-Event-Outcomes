// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PredictionMarket is Ownable {
    enum Outcome { Undecided, Yes, No }

    struct Bet {
        uint256 amount;
        Outcome outcome;
    }

    struct Market {
        string question;
        uint256 deadline;
        Outcome result;
        bool resolved;
        uint256 totalYes;
        uint256 totalNo;
        mapping(address => Bet) bets;
        bool exists;
    }

    uint256 public marketIdCounter;
    mapping(uint256 => Market) private markets;

    event MarketCreated(uint256 indexed marketId, string question, uint256 deadline);
    event BetPlaced(uint256 indexed marketId, address indexed user, Outcome outcome, uint256 amount);
    event MarketResolved(uint256 indexed marketId, Outcome result);
    event RewardClaimed(uint256 indexed marketId, address indexed user, uint256 reward);

    constructor(address initialOwner) Ownable(initialOwner) {}

    modifier marketExists(uint256 marketId) {
        require(markets[marketId].exists, "Market does not exist");
        _;
    }

    function createMarket(string memory _question, uint256 _deadline) external onlyOwner {
        require(_deadline > block.timestamp, "Invalid deadline");
        Market storage m = markets[marketIdCounter];
        m.question = _question;
        m.deadline = _deadline;
        m.result = Outcome.Undecided;
        m.exists = true;

        emit MarketCreated(marketIdCounter, _question, _deadline);
        marketIdCounter++;
    }

    function placeBet(uint256 marketId, Outcome _outcome) external payable marketExists(marketId) {
        Market storage m = markets[marketId];
        require(block.timestamp < m.deadline, "Market closed");
        require(_outcome == Outcome.Yes || _outcome == Outcome.No, "Invalid outcome");
        require(msg.value > 0, "Zero bet amount");
        require(m.bets[msg.sender].amount == 0, "Already placed bet");

        m.bets[msg.sender] = Bet(msg.value, _outcome);

        if (_outcome == Outcome.Yes) {
            m.totalYes += msg.value;
        } else {
            m.totalNo += msg.value;
        }

        emit BetPlaced(marketId, msg.sender, _outcome, msg.value);
    }

    function resolveMarket(uint256 marketId, Outcome _result) external onlyOwner marketExists(marketId) {
        Market storage m = markets[marketId];
        require(block.timestamp >= m.deadline, "Market still active");
        require(!m.resolved, "Already resolved");
        require(_result == Outcome.Yes || _result == Outcome.No, "Invalid result");

        m.result = _result;
        m.resolved = true;

        emit MarketResolved(marketId, _result);
    }

    function claimReward(uint256 marketId) external marketExists(marketId) {
        Market storage m = markets[marketId];
        require(m.resolved, "Market not resolved");

        Bet storage userBet = m.bets[msg.sender];
        require(userBet.amount > 0, "No bet");
        require(userBet.outcome == m.result, "Wrong prediction");

        uint256 reward;
        if (m.result == Outcome.Yes) {
            reward = (userBet.amount * (m.totalYes + m.totalNo)) / m.totalYes;
        } else {
            reward = (userBet.amount * (m.totalYes + m.totalNo)) / m.totalNo;
        }

        userBet.amount = 0;
        payable(msg.sender).transfer(reward);

        emit RewardClaimed(marketId, msg.sender, reward);
    }

    function getMarket(uint256 marketId)
        external
        view
        returns (string memory, uint256, Outcome, bool, uint256, uint256)
    {
        Market storage m = markets[marketId];
        return (m.question, m.deadline, m.result, m.resolved, m.totalYes, m.totalNo);
    }

    function getUserBet(uint256 marketId, address user) external view returns (uint256, Outcome) {
        Bet storage b = markets[marketId].bets[user];
        return (b.amount, b.outcome);
    }
}
