// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  // <owner>
  address public owner = msg.sender;

  // <skuCount>
  uint public skuCount;

  // <items mapping>
  mapping(uint => Item) public items;

  // <enum State: ForSale, Sold, Shipped, Received>
  enum State{ ForSale, Sold, Shipped,  Received}

  // <struct Item: name, sku, price, state, seller, and buyer>
  struct Item { 
   string name;
   uint sku;
   uint price;
   State state;
   address payable seller;
   address payable buyer;
}
  /* 
   * Events
   */

  // <LogForSale event: sku arg>
  event LogForSale(uint sku);

  // <LogSold event: sku arg>
  event LogSold(uint sku);

  // <LogShipped event: sku arg>
  event LogShipped(uint sku);

  // <LogReceived event: sku arg>
  event LogReceived(uint sku);

   modifier isOwner (address _address) { 
    require (_address == msg.sender); 
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint _sku){
    require((items[_sku].seller != address(0)) && (items[_sku].state == State.ForSale), "Not for sale");
    _;
  }
  
  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold);
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped);
    _;
  }

  modifier received(uint _sku) {
    require(items[_sku].state == State.Received);
    _;
  }

  constructor() public {
    // 1. Set the owner to the transaction sender
    owner = msg.sender;
    // 2. Initialize the sku count to 0. Question, is this necessary?
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    // 1. Create a new item and put in array

    items[skuCount] = Item({
     name: _name, 
     sku: skuCount, 
     price: _price, 
     state: State.ForSale, 
     seller: msg.sender, 
     buyer: address(0)
    });

    // 2. Increment the skuCount by one

    skuCount += 1;

    // 3. Emit the appropriate event

    emit LogForSale(skuCount);

    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price ) checkValue(sku) {
     // 2. this should transfer money to the seller,
    items[sku].seller.transfer(items[sku].price);
    // 3. set the buyer as the person who called this transaction, 
    items[sku].buyer = msg.sender;
    // 4. set the state to Sold.
    items[sku].state = State.Sold; 
    // 6. call the event associated with this function!
    emit LogSold(sku);
  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
    items[sku].state = State.Shipped;
    emit LogShipped(sku);
  }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint _sku) public view 
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  { 
    name = items[_sku].name; 
    sku = items[_sku].sku; 
    price = items[_sku].price; 
     state = uint(items[_sku].state);
     seller = items[_sku].seller; 
     buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
   } 
}
