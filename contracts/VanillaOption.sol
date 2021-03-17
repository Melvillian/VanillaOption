//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface VanillaOption is IERC1155 {

  event OptionMinted(

  );

  event WriterExecuted(

  );

  event BuyerExecuted(

  );

}
