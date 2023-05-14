// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ERC948 {

    event NewSubscription(
        address _ownerAddress,
        uint _periodMultiplier,
        uint _startTime
    );

    struct Subscription {
        uint periodMultiplier;
        uint startTime;
        uint nextPaymentTime;
        bool active;
    }

    uint256 constant PERIOD_LENGTH = 30 days;


    mapping (address => Subscription) public subscriptions;

    ERC20 subscriptionToken;
    address payeeAddress;
    uint256 baseAmountRecurring;


    constructor(
        address _subscriptionTokenAddress,
        address _payeeAddress,
        uint256 _baseAmountRecurring
    ){
        subscriptionToken = ERC20(_subscriptionTokenAddress);
        payeeAddress = _payeeAddress;
        baseAmountRecurring = _baseAmountRecurring;

    }

    function createSubscription(uint256 _periodMultiplier) external {
        // check that subscription does not exist
        require(
            subscriptions[msg.sender].active == false,
            "subscription already exists"
        );
        
        // calculate required amount 
        uint _amountRecurring = baseAmountRecurring * PERIOD_LENGTH;

        // check that balance is greater than amountRequired
        require(
            subscriptionToken.balanceOf(msg.sender) >= _amountRecurring,
            "Insufficient balance for initial + 1x recurring amount"
        );

        // Check that contact has approval for at least the initial and first recurring payment
        require(
            subscriptionToken.allowance(
                msg.sender,
                address(this)
            ) >= _amountRecurring,
            "Insufficient approval for initial + 1x recurring amount"
        );

        uint256 _startTime = block.timestamp;

        Subscription memory newSubscription = Subscription({
            periodMultiplier: _periodMultiplier,
            startTime: _startTime,
            active: true,
            nextPaymentTime: block.timestamp + _periodMultiplier
        });

        subscriptions[msg.sender] = newSubscription;

        // Make initial payment
        subscriptionToken.transferFrom(msg.sender, payeeAddress, _amountRecurring);

        // Emit NewSubscription event
        emit NewSubscription(
            msg.sender,
            _periodMultiplier,
            _startTime
        );
    }
    
    /**
    * @dev check if address is Subscribed
    * @param _address Address for which the condition is checked
    * @return true if address is subscribed false otherwise
    */
    function isSubscribed(address _address) external view returns(bool){
        return subscriptions[_address].active;
    }

    /**
    * @dev Delete a subscription
    * @return true if the subscription has been deleted
    */
    function cancelSubscription()
        public
        returns (bool)
    { 
        require(subscriptions[msg.sender].active == true);
        delete subscriptions[msg.sender];
        return true;
    }

    /**
    * @dev Check whether payment is due
    * @param _subscriptionOwner owner of the subcription for which to check whether subcription is due
    * @return true if the subscription has been deleted
    */
    function paymentDue(address _subscriptionOwner)
        public
        view
        returns (bool)
    {
        Subscription memory subscription = subscriptions[_subscriptionOwner];

        // Check this is an active subscription
        require((subscription.active == true), 'Not an active subscription');

        // Check that subscription start time has passed
        require((subscription.startTime <= block.timestamp),
            'Subscription has not started yet');

        // Check whether required time interval has passed since last payment
        if (subscription.nextPaymentTime <= block.timestamp) {
            return true;
        }
        else {
            return false;
        }
    }

    /**
    * @dev Called by or on behalf of the merchant, in order to initiate a payment.
    * @return A boolean to indicate whether the payment was successful
    */
    function processSubscription(
        address _ownerAddress
    ) public returns (bool) {
        Subscription storage subscription = subscriptions[_ownerAddress];

        uint256 _amountRecurring = subscription.periodMultiplier * baseAmountRecurring;

        require(paymentDue(_ownerAddress),
            "A Payment is not due for this subscription");

        subscriptionToken.transferFrom(
            _ownerAddress,
            payeeAddress,
            _amountRecurring
        );

        // Increment subscription nextPaymentTime by one interval
        uint256 interval = subscription.periodMultiplier * PERIOD_LENGTH;
        subscription.nextPaymentTime += interval;
        return true;
    }
}