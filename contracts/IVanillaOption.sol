//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// OPEN QUESTIONS (PLEASE THINK ABOUT THESE AND HELP ME ANSWER THEM):
// - What is the proper way to communicate to the user of IVanillaOption the units of the strike?
// - Can we do it without specifying a whole other `payment` token (which doesn't even get used in cash settled options!)
// use an ERC1155 contract with only 2 subtokens (at indices 0 and 1) and 0 = bToken and 1 = wToken.
// another would be to use a struct. I'm thinking of going with struct, because we need something to represent
// the options series parameters (strike price, expiration date, isCall)
// - is there a way to use a single EIP standard that works for both ERC20 and ERC1155? That way
// IVanillaOption can be used with underlying assets their are EITHER regular tokens or NFTs. Right
// now the only way I see to do this is to have two separate versions of the IVanillaOption interface;
// one for ERC20 and one for ERC1155, because it's not backwards compatible
// - do we even need to be backwards compatible with ERC20? We know the ERC20-compatible option tokens
// can't be traded on ERC20-compatible DEX's, because of time decay. So maybe we just leave
// the whole ERC20/ERC1155 distinction alone.
interface IVanillaOption {

  event OptionMinted(
    // TODO
  );

  event WriterExecuted(
    // TODO
  );

  event BuyerExecuted(
    // TODO
  );

  // The option's underlying asset token may be an ERC20 (e.g. WBTC) or
  // an NFT, so we need a way for the interface to tell the user which of
  // these it is. Used in IVanillaOption.underlyingType
  // TODO: figure out if it's possible to unite ERC20 and ERC1155 under a single type
  // so we don't need this distinction
  enum UnderlyingType {
    ERC20,
    ERC1155
  }

  struct Series {
    uint256 expirationDate;
    uint256 strike;
    string description;
    IERC20 underlying; // TODO: should this be an ERC1155, or just a plain address and let the callers cast it to correct type?
    IERC20 payment; // should be the 0x0 address for cash settled
    bool isCall;
    bool isCashSettled;
  }

  ////////////////////////// Mutating Functions //////////////////////////

  // mints IERC1155
  function mintOption(uint256 id, uint256 amount) external;

  // returns the amounts of collateral releaseable by the buyer and the writer, respectively.
  // Note: you must call IVanillaOption.exercise before these funds can actually be released
  // questions:
  // - should this return the amounts _after_ taking fees into account, or _before_? Should
  // the protocol even answer that question? Preferrably not, but it might lead to fragmentation
  // in meanings for implementors
  // - should there be more than just 2 positions to take (buyer and writer?)
  function getSettlementAmounts(uint256 id, uint256 amount) external returns (uint256, uint256);

  // exercises both buyer and writers positions, approving them to transfer out the appropriate amounts
  // of collateral at their leisure. This means whoever wants their money first has to
  // pay for the "loser"'s withdrawal (small consolation :D).
  // NOTE ON THE ABOVE: This assumes VanillaOption is a European option, because if it was American
  // then you certainly wouldn't want your counterparty's settling to affect your position (they might
  // settle your position before you want!). It might be fine (needs more thought) if we ignore American
  // options, because it is usually not rational to exercise your options early, so why even support that use
  // case if it's known to be sub-optimal?
  function settle(uint256 id, uint256 amount, bytes calldata data) external;

  // burn amount's worth of subtokens (possibly multiple) in order to
  // get the underlying collateral back
  //
  // questions:
  // - should there be multiple token arguments (which would happen if it made sense for
  // the underlying protocol to want to burn coins in unequal proportions. Maybe this
  // could be solved by having the implementation use a constant "multiplier" to account for this?)
  function closePosition(uint256 id, uint256 amount) external;

  ////////////////////////// View Functions //////////////////////////

  // Returns true if the given option is settleable
  function settleable(uint256 id) view external returns (bool);

  // Checks if the option buyer would receive non-zero returns if they settled the option
  // questions:
  // - should this be non-binary? Could there be more than 1 state? If so, this should be a function
  // called state() that returns a uint8
  function isITM(uint256 id) view external returns (bool);

  // returns the data about the option series at index id (e.g. expiration date, strike, cash settled or not, call or put, and description)
  // questions:
  // - same question as in getSettlementAmounts; should there be just 2 positions to take (buyer and writer)?
  function getSeries(uint256 id) view external returns (Series memory);

  function balancerOfBuyer(address owner, uint256 id) view external returns (uint256);

  function balanceOfWriter(address owner, uint256 id) view external returns (uint256);

  // returns the strike price of the option at index id
  // questions:
  // - should the function specify the units of the strike price? Leaving it
  // ambiguous might result in fragmentation
  function strike(uint256 id) view external returns (uint256);

  // returns the expiration date of the option at index id (in seconds after epoch)
  function expirationDate(uint256 id) view external returns (uint256);

  // returns true if the option at index id is a Call, otherwise it's a Put
  function isCall(uint256 id) view external returns (bool);

  // returns the cost to buy amount worth of the option at index id
  function premium(uint256 id, uint256 amount) view external returns (uint256);

  // returns true if the option at index is is cash settled, otherwise it's
  // physically settled, and returns false
  function isCashSettled(uint256 id) view external returns (bool);

  // returns the type of ERC interface the underlying token asset supports
  // currently one of ERC20 or ERC1155
  function underlyingType(uint256) view external returns (UnderlyingType);
}
