pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleCoin is ERC20 {
  constructor() ERC20("SimpleCoin", "SC")  {
    _mint(msg.sender, 1000*10**18);
  }
}
