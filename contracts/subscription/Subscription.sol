// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ERC948 {

    enum PeriodType {
        Second,
        Day, 
        Week, 
        Month,
        Year
    }

    struct Subscription {
        address payeeAddress;
        uint amountRecurring;
        uint amountInitial;
        uint periodType;
        uint periodMultiplier;
        uint startTime;
        string data;
        bool active;
        uint nextPaymentTime;
        // uint terminationDate;
    }
    mapping (address => Subscription) public subscriptions;

    ERC20 subscriptionToken;

    event NewSubscription(
        address _ownerAddress,
        address _payeeAddress,
        uint _amountRecurring,
        uint _amountInitial,
        uint _periodType,
        uint _periodMultiplier,
        uint _startTime
    );


    constructor(address subscriptionTokenAddress){
        subscriptionToken = ERC20(subscriptionTokenAddress);
    }
    function createSubscription(
        address _payeeAddress,
        uint _amountRecurring,
        uint _amountInitial,
        uint _periodType,
        uint _periodMultiplier,
        uint _startTime,
        string calldata _data
        )
        external
        virtual
        subscriptionNotActive
    {
        // Ensure that _periodType is valid
        // TODO support hour, day, week, month, year
        require((_periodType == 0),
                'Only period types of second are supported');

        // Check that subscription start time is now or in the future
        require((_startTime >= block.timestamp),
                'Subscription must not start in the past');

        uint amountRequired = _amountInitial + _amountRecurring;
        require((subscriptionToken.balanceOf(msg.sender) >= amountRequired),
                'Insufficient balance for initial + 1x recurring amount');

        //  Check that contact has approval for at least the initial and first recurring payment
        require(
            subscriptionToken.allowance(
                msg.sender,
                address(this)
            ) >= amountRequired,
            'Insufficient approval for initial + 1x recurring amount'
        );

        Subscription memory newSubscription = Subscription({
            payeeAddress: _payeeAddress,
            amountRecurring: _amountRecurring,
            amountInitial: _amountInitial,
            periodType: _periodType,
            periodMultiplier: _periodMultiplier,

            // TODO set start time appropriately and deal with interaction w nextPaymentTime
            startTime: block.timestamp,

            data: _data,
            active: true,

            // TODO support hour, day, week, month, year
            nextPaymentTime: block.timestamp + _periodMultiplier
        });

        subscriptions[msg.sender] = newSubscription;

        // Make initial payment
        subscriptionToken.transferFrom(msg.sender, _payeeAddress, _amountInitial);

        // Emit NewSubscription event
        emit NewSubscription(
            msg.sender,
            _payeeAddress,
            _amountRecurring,
            _amountInitial,
            _periodType,
            _periodMultiplier,
            _startTime
        );
    }

    /**
    * @dev Delete a subscription
    * @return true if the subscription has been deleted
    */
    function cancelSubscription()
        public
        subscriptionIsActive
        returns (bool)
    {
        delete subscriptions[msg.sender];
        return true;
    }


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
    * @param _amount Amount to be transferred, can be lower than total allowable amount
    * @return A boolean to indicate whether the payment was successful
    */
    function processSubscription(
        address _ownerAddress,
        uint _amount
        )
        public
        returns (bool)
    {
        Subscription storage subscription = subscriptions[_ownerAddress];

        require((_amount <= subscription.amountRecurring),
            'Requested amount is higher than authorized');

        require((paymentDue(_ownerAddress)),
            'A Payment is not due for this subscription');

        subscriptionToken.transferFrom(
            _ownerAddress,
            subscription.payeeAddress,
            _amount
        );

        // Increment subscription nextPaymentTime by one interval
        // TODO support hour, day, week, month, year
        subscription.nextPaymentTime = subscription.nextPaymentTime + subscription.periodMultiplier;
        return true;
    }

    function isSubscribed(address _userAddress) external view returns(bool){
        return subscriptions[_userAddress].active;
    }


    modifier subscriptionNotActive(){
        if(subscriptions[msg.sender].active = false){
            _;
        }
    }

    modifier subscriptionIsActive(){
        if(subscriptions[msg.sender].active = true){
            _;
        }
    }
}