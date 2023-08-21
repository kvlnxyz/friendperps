// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IFriendtechSharesV1} from "./IFriendtechSharesV1.sol";

pragma solidity ^0.8.9;

contract Perp {

    struct Position {
        uint256 notional;
        uint256 collateral;
        uint256 price;
        bool long;
    }

    address public owner;

    address public WETH;
    address public cobie;
    IFriendtechSharesV1 public FriendtechSharesV1;

    uint256 public lpSize;
    uint256 public lpFees;
    mapping(address => uint256) public lpShare;
    mapping(address => uint256) public lpClaimed;

    mapping(address => Position) public positionOf;

    constructor(address _WETH, address _FriendtechSharesV1, address _cobie) {
        WETH = _WETH;
        FriendtechSharesV1 = IFriendtechSharesV1(_FriendtechSharesV1);
        cobie = _cobie;
        owner = msg.sender;
    }

    function getPrice() public view returns(uint256) {
        return FriendtechSharesV1.getBuyPriceAfterFee(cobie, 1);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        ERC20 token = ERC20(WETH);
        require(token.allowance(from, to) >= amount, "Insufficient allowance!");
        token.transferFrom(from, to, amount);
    }

    function _position(address trader) public view returns (uint256, bool) {
        uint256 notional = positionOf[trader].notional;
        uint256 collateral = positionOf[trader].collateral;
        uint256 price = positionOf[trader].price;
        bool long = positionOf[trader].long;

        uint256 newPrice = getPrice();

        if (long) {
            uint256 percentGain = ((newPrice - price) / price) * 100;
            uint256 notionalGain = notional * percentGain;
            uint256 newNotional = notional + notionalGain;
            require(notional - (collateral * 2 / 10) >= newNotional, "Position in the red!");
            return (notionalGain, true);
        } else {
            uint256 percentGain = ((price - newPrice) / price) * 100;
            uint256 notionalGain = notional * percentGain;
            uint256 newNotional = notional + notionalGain;
            require(notional - (collateral * 2 / 10) >= newNotional, "Position in the red!");
            return (notionalGain, true);
        }
    }

    // TRADER //

    function open(uint256 notional, uint256 collateral, bool long) public {
        require(positionOf[msg.sender].notional == 0, "Position already open!");
        uint256 collateralAfterFees = collateral - ((collateral * 2)/10);
        require(notional / collateralAfterFees >= 5, "Insufficient collateral!");
        lpFees += collateral - collateralAfterFees;
        _transfer(msg.sender, address(this), collateral);
        positionOf[msg.sender] = Position(notional, collateralAfterFees, getPrice(), long);
    }

    function close() public {
        (uint256 amount, bool green) = _position(msg.sender);
        require(green == true, "Position in the red!");
        _transfer(address(this), msg.sender, amount);
    }

    // LP //

    function lpAdd(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0!");
        _transfer(msg.sender, address(this), amount);
        lpSize += amount;
        lpShare[msg.sender] += amount;
    }

    function lpRemove(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0!");
        lpSize -= amount;
        lpShare[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount);
    }

    function lpClaim() public {
        uint256 amount = lpShare[msg.sender] * lpFees / lpSize;
        amount -= lpClaimed[msg.sender];
        lpClaimed[msg.sender] += amount;
        _transfer(address(this), msg.sender, amount);
    }

    // LIQUIDATOR //

    function liq(address trader) public {
        ( , bool green) = _position(msg.sender);
        require(green == false, "Position in the green!");
        _transfer(address(this), msg.sender, positionOf[trader].collateral);
    }

}
