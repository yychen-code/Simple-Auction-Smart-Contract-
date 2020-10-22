pragma solidity >=0.5 <0.6.0;

contract SimpleAuction
        {
        // The Beneficiary who has made the highest bid address public beneficiary
        address payable public beneficiary; 
        // The Time at which the Auction end
        uint public auctionEndTime; 
        // Track address of the highest bidder public
        address public highestBidder;      
        //Track the higest bid amount 
        uint public highestBid;             
        //Allowed withdrawals of previous bids
        mapping(address => uint) pendingReturns; 
        //Set to true at the end to prevent any changes.
        bool ended;    
        //set the minimal bid value
        uint public minBid;                         
        //set the minimum increment for a new bid
        uint public minIncrement;
        //Add the name of bidders  
        string public bidderName;
        //add the name of the highest bidder
        string public beneficiaryName;     
        // create a enum for the state of goods 
        enum State {AWAITING_PAYMENT,AWAITING_Delivery,COMFIRED_Derlivery}
        State public currState;
        
         
        // events that will be triggered on changes of the paramets pass in.
        event HighestBidIncreased(address bidder, uint amount); 
        event AuctionEnded(address winner, uint amount);
        
        
        
        
// declare the public parameters in the constructor
constructor(uint _biddingTime,address payable _beneficiary,string memory _beneficiaryName,uint _minBid,uint _minIncrement) 
    public 
        {
        beneficiary = _beneficiary;
        beneficiaryName =_beneficiaryName;
        auctionEndTime = now + (_biddingTime * 1 seconds);
        minBid=_minBid;
        minIncrement= _minIncrement;
        //highestBidder=_highestBidder;
        }
        
// The bid function() is to ensure:
//1.bids are make before the end of auction time.
//2.current bid is higher than previous bid 
//3.current bid must be higher than the minimum set bid
//4.The current bid must be at least the minimum increament over the current highest bid 
//5. Ensure that bid have ether attached as deposite to ensure no fraud 
function bid() public payable
        {
        require(now <= auctionEndTime,"Auction already ended.");
        require(msg.value >= highestBid,"There already is a higher bid.");
        require(msg.value >=minBid);
        require(msg.value >= pendingReturns[highestBidder] + minIncrement);
                
        if (highestBid != 0) 
            {
            pendingReturns[highestBidder] += highestBid;
            minBid = highestBid;    
            }
            
            highestBidder = msg.sender;
            highestBid = msg.value;
            emit HighestBidIncreased(msg.sender, msg.value);
            }
// The withdraw() function is to ensure:
//1. The ether is not refund to the highest bidder
//2. if there is entry in the pendingReturns map for the given sender
//3. if there is no entry in the pendinReturns then return false
//4. if there is entry in the pendingReturns then set the value to zero and send the ether to the sender. Then return Ture.

function withdraw() public returns (bool) 
        {
        uint amount = pendingReturns[msg.sender];
        
        if (amount > 0)
            {pendingReturns[msg.sender] = 0;
            
        if (!msg.sender.send(amount))
            {
            pendingReturns[msg.sender] = amount;
            return false;
            }
        }
        return true;
        }

// The aucitonEnd() function ensure: 
//1. end the auction and send the highest bid to the beneficiary
function auctionEnd() public 
        {
        require(now >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
        }
        
modifier onlyHighestBidder(){
        require(msg.sender == highestBidder, "Only buyer can call this method");
        _;
}

function deposite() onlyHighestBidder external payable{
        require(currState == State.AWAITING_PAYMENT, "Already Paid");
        currState = State.AWAITING_Delivery;
}
function confirmDelivery() onlyHighestBidder external{
        require(currState == State.AWAITING_Delivery, "Cannot confirm delivery");
        beneficiary.transfer(address(this).balance);
        currState = State.COMFIRED_Derlivery;
}
    
}
    
