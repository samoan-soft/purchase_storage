// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;
pragma experimental ABIEncoderV2;

contract Purchase
{
    enum State { Created, Locked, Inactive }
    State public state;
    struct Product 
    // структура описывающая товар
    {
        address owner; // Адрес владельца
        uint256 ID; // ID товара 
        uint256 current_cost; // цена
        string name; // название товара
    }

    mapping (address => Product[]) public Products;
    Product[] public ProductsBuf;

    Product A;

    uint256 globalID = 0;
    uint256 constant globalCost = 1;

    address payable public seller;
    address payable public buyer;

    modifier condition(bool _condition)
    {
        require(_condition, "condition_error");
       _;
    }
    modifier onlyBuyer()
    {
        require(msg.sender == buyer, "onlyBuyer_error");
        _;
    }
    modifier onlySeller()
    {
        require(msg.sender == seller, "onlySeller_error");
        _;
    }
    modifier inState(State _state)
    {
        require(state == _state, "inState_error");
       _;
    }
    modifier notSeller() {
        require(msg.sender != seller, "notSeller_error");
        _;
    }


    event Refuse();
    event Confirm();
    event Receive();


    function initProduct(string memory _name) public 
    {
        A = Product(msg.sender, globalID++, globalCost, _name);
        Products[msg.sender].push(A);
    }

    function getProduct(address _owner, uint256 productId_) public view returns(Product memory buf)
    {
        Product memory C;
        C = Products[_owner][searchIndex(msg.sender, productId_)];
        return C;
    }

    function getProduct(address _owner) public view returns(Product[] memory buf)
    {
        Product[] memory C;
        C = Products[_owner];
        return C;
    }

    function deleteProduct(address _owner, uint256 _ID) internal returns(Product memory buf)
    {
        Product memory C;
        delete ProductsBuf;
        uint256 j = 0;

        for(uint i = 0; i <Products[_owner].length; i++)
        {
           if(Products[_owner][i].ID != _ID)
           {
               ProductsBuf.push(Products[_owner][i]);
               j++;
           }
           else
           {
               C = Products[_owner][i];
           }
        }
        Products[_owner] = ProductsBuf;
        return C;
    }

    function init(uint productId_) public payable condition(msg.value == (2 * Products[msg.sender][searchIndex(seller, productId_)].current_cost*1000000000000000000))
    {
        seller = address(uint160(msg.sender));

        state = State.Created;
    }

    function refuse(uint productId_) public notSeller inState(State.Created)
    {
        emit Refuse();
        state = State.Inactive;
        seller.transfer(2 * Products[seller][searchIndex(seller, productId_)].current_cost*1000000000000000000); 
    }

    function confirm(uint productId_) public payable notSeller inState(State.Created)  condition(msg.value == (2 * Products[seller][searchIndex(seller, productId_)].current_cost*1000000000000000000))
    {
        emit Confirm();
        buyer = address(uint160(msg.sender));
        state = State.Locked;
    }

    function received(uint productId_) public onlySeller inState(State.Locked)
    {
        emit Receive();
        buyer.transfer(Products[seller][searchIndex(seller, productId_)].current_cost*1000000000000000000); 
        seller.transfer(3 * Products[seller][searchIndex(seller, productId_)].current_cost*1000000000000000000);
        Products[buyer].push(deleteProduct(seller, productId_));
        state = State.Inactive;
    }

    function searchIndex(address owner, uint productId_) public view returns(uint index) {
        uint j = 0;
        for (uint i = 0 ; i < Products[owner].length; i++ ) {
            if (productId_ == Products[owner][i].ID) {
                j = i;
                break;
            }
        }
        return j;
    }
}