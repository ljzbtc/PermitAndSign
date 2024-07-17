
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@author liujingze
///@dev withdraw and deposit ERC20 token
///@notice this contract only accept specific ERC20 token

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract TokenBank{

    // the address of the ERC20 token that this contract accept
    address immutable public IEC20_TOKEN_ADDRESS;

    event Deposit(address indexed _from, uint _amount);
    event Withdraw(address indexed _to, uint _amount);

    mapping(address => uint) public AddressToAmount;

    constructor(address _IEC20_TOKEN) {
        IEC20_TOKEN_ADDRESS = _IEC20_TOKEN;
    }

    // deposit ERC20 token to this contract
    function deposit(uint _amount) public {

        bool result = IERC20(IEC20_TOKEN_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(result, "DepositFailed");
        AddressToAmount[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function permitDeposit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        IERC20Permit(IEC20_TOKEN_ADDRESS).permit(owner, spender, value, deadline, v, r, s);
        bool result = IERC20(IEC20_TOKEN_ADDRESS).transferFrom(
            owner,
            address(this),
            value
        );
        require(result, "DepositFailed");
        AddressToAmount[owner] += value;
    }

    function withdraw( uint _amount) public {
        require(
            AddressToAmount[msg.sender] >= _amount,
            "InsufficientBalance"
        );

        AddressToAmount[msg.sender] -= _amount;
        bool result = IERC20(IEC20_TOKEN_ADDRESS).transfer(msg.sender, _amount);
        require(result, "WithdrawFailed");

        emit Withdraw(msg.sender, _amount);
    }

    function getBalance(address _owner) public view returns (uint) {
        return AddressToAmount[_owner];
    }

    function getAllowance() public view returns (uint) {
        return IERC20(IEC20_TOKEN_ADDRESS).allowance(msg.sender, address(this));
    }

    function tokensReceived(
        address from,
        uint amount,
        bytes memory
    ) public returns (bool) {

        require(msg.sender == IEC20_TOKEN_ADDRESS, "Only accept specific ERC20 token");
        AddressToAmount[from] += amount;
        emit Deposit(from, amount);
        return true;
    }
}