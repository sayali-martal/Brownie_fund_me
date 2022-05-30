// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// Import from chainlink
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // For uint wrapping
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // Get called the moment contract is deployed
    // PriceFeed is used to use the custom chain/address
    constructor(address _priceFeed) public {
        // Global priceFeed address
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // Accept the payment
    function fund() public payable {
        // Set minimum value
        uint256 minimumUsd = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUsd, "Need minimum $50 ETH to complete the transaction");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // Get version of AggregatorV3Interface
    function getVersion() public view returns(uint256) {
        return priceFeed.version();
    }

    // ETH -> USD conversion rate
    function getPrice() public view returns(uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // Price in WEI
        return uint256(answer * 10000000000);
    }

    // Convert ETH -> USD 
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        // Both ethPrice and EthAmount has 10^18 taggedto it
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10 ** 18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        // Runs function wherever underscore is present
        _;
    }

    // Send to only owner
    function withdraw() payable onlyOwner public {
        // Transfers the amount
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // Reset funder array
        funders = new address[](0);
    }
}
