// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.5.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../../../interfaces/ICToken.sol";

import "../../../interfaces/IAssimilator.sol";

import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract MainnetUsdcToCUsdcAssimilator is IAssimilator {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    ICToken constant cusdc = ICToken(0x39AA39c021dfbaE8faC545936693aC917d5E7563);

    uint256 constant ZEN_DELTA = 1e6;

    constructor () public { }

    event log_uint(bytes32, uint256);

    // takes raw amount of usdc, transfers it in, wraps it in cusdc, returns numeraire amount
    function intakeRaw (uint256 _amount) public returns (int128 amount_) {

        usdc.transferFrom(msg.sender, address(this), _amount);

        uint256 success = cusdc.mint(_amount);

        if (success != 0) revert("CUsdc/mint-failed");

        uint256 _rate = cusdc.exchangeRateStored();

        amount_ = ( ( ( ( _amount * 1e18 ) / _rate ) * _rate ) / 1e18 ).divu(1e6);

    }

    // takes raw amount of usdc, transfers it in, wraps it in cusdc, returns numeraire amount
    function intakeRawAndGetBalance (uint256 _amount) public returns (int128 amount_, int128 balance_) {

        usdc.transferFrom(msg.sender, address(this), _amount);

        uint256 success = cusdc.mint(_amount);

        if (success != 0) revert("CUsdc/mint-failed");

        uint256 _balance = cusdc.balanceOf(address(this));

        uint256 _rate = cusdc.exchangeRateStored();

        amount_ = ( ( ( ( _amount * 1e18 ) / _rate ) * _rate ) / 1e18 ).divu(1e6);

        balance_ = ( ( _balance * _rate ) / 1e18 ).divu(1e6);

    }

    // takes numeraire amount of usdc, calculates raw amount, transfers it in and wraps it in cusdc, returns raw amount
    function intakeNumeraire (int128 _amount) public returns (uint256 amount_) {

        amount_ = _amount.mulu(1e6);

        usdc.transferFrom(msg.sender, address(this), amount_);

        uint256 success = cusdc.mint(amount_);

        if (success != 0) revert("CUsdc/mint-failed");

    }

    // takes raw amount of usdc, unwraps it from cusdc, transfers that out, returns numeraire amount
    function outputRaw (address _dst, uint256 _amount) public returns (int128 amount_) {

        uint256 success = cusdc.redeemUnderlying(_amount);

        if (success != 0) revert("CUsdc/redeemUnderlying-failed");

        usdc.transfer(_dst, _amount);

        amount_ = _amount.divu(1e6);

    }

    // takes raw amount of usdc, unwraps it from cusdc, transfers that out, returns numeraire amount
    function outputRawAndGetBalance (address _dst, uint256 _amount) public returns (int128 amount_, int128 balance_) {

        uint256 success = cusdc.redeemUnderlying(_amount);

        if (success != 0) revert("CUsdc/redeemUnderlying-failed");

        usdc.transfer(_dst, _amount);

        uint256 _balance = cusdc.balanceOf(address(this));

        uint256 _rate = cusdc.exchangeRateStored();

        balance_ = ( ( _balance * _rate ) / 1e18 ).divu(1e6);

        amount_ = _amount.divu(1e6);

    }

    // takes numeraire amount of usdc, calculates raw amount, unwraps raw amount of cusdc, transfers that out, returns raw amount
    function outputNumeraire (address _dst, int128 _amount) public returns (uint256 amount_) {

        amount_ = _amount.mulu(1e6);

        uint256 success = cusdc.redeemUnderlying(amount_);

        if (success != 0) revert("CUsdc/redeemUnderlying-failed");

        usdc.transfer(_dst, amount_);

    }

    // takes numeraire amount, returns raw amount
    function viewRawAmount (int128 _amount) public returns (uint256 amount_) {

        amount_ = _amount.mulu(1e6);

    }

    // takes raw amount, returns numeraire amount
    function viewNumeraireAmount (uint256 _amount) public  returns (int128 amount_) {

        amount_ = _amount.divu(1e6);

    }

    // returns numeraire amount of reserve asset, in this case cUsdc
    function viewNumeraireBalance () public returns (int128 balance_) {

        uint256 _rate = cusdc.exchangeRateStored();

        uint256 _balance = cusdc.balanceOf(address(this));

        if (_balance == 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ( ( _balance * _rate ) / 1e18 ).divu(1e6);

    }

    function viewNumeraireAmountAndBalance (uint256 _amount) public returns (int128 amount_, int128 balance_) {

        amount_ = _amount.divu(1e6);

        uint256 _rate = cusdc.exchangeRateStored();

        uint256 _balance = cusdc.balanceOf(address(this));

        if (_balance == 0) return ( amount_, ABDKMath64x64.fromUInt(0) );

        balance_ = ( ( _balance * _rate ) / 1e18 ).divu(1e6);

    }

}