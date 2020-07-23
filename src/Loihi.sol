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

import "abdk-libraries-solidity/ABDKMath64x64.sol";

import "./Assimilators.sol";

import "./Controller.sol";

import "./Liquidity.sol";

import "./PartitionedLiquidity.sol";

import "./ProportionalLiquidity.sol";

import "./SelectiveLiquidity.sol";

import "./Shells.sol";

import "./Swaps.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20NoBool.sol";

contract Loihi {

    int128 constant ONE = 0x10000000000000000;

    string  public constant name = "Shells";
    string  public constant symbol = "SHL";
    uint8   public constant decimals = 18;

    using ABDKMath64x64 for int128;
    using UnsafeMath64x64 for int128;
    using ABDKMath64x64 for uint;

    using Assimilators for address;
    using ShellMath for Shell;
    using Shells for Shell;
    using Controller for Shell;

    struct Shell {
        int128 alpha;
        int128 beta;
        int128 delta;
        int128 epsilon;
        int128 lambda;
        int128 omega;
        int128[] weights;
        uint totalSupply;
        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowances;
        Assimilator[] reserves;
        Assimilator[] numeraires;
        mapping (address => Assimilator) assimilators;
        bool testHalts;
    }

    struct Assimilator {
        address addr;
        uint8 ix;
    }

    Shell public shell;

    struct PartitionTicket {
        uint[] claims;
        bool active;
    }

    mapping (address => PartitionTicket) public partitionTickets;

    address[] public numeraires;

    bool public partitioned = false;
    bool public frozen = false;

    address public owner;
    bool internal notEntered = true;

    uint public maxFee;

    event ShellsMinted(address indexed minter, uint amount, address[] indexed coins, uint[] amounts);
    event ShellsBurned(address indexed burner, uint amount, address[] indexed coins, uint[] amounts);
    event Trade(address indexed trader, address indexed origin, address indexed target, uint originAmount, uint targetAmount);
    event Transfer(address indexed from, address indexed to, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetFrozen(bool isFrozen);

    modifier onlyOwner() {
        require(msg.sender == owner, "Shell/caller-is-not-owner");
        _;
    }

    modifier nonReentrant() {

        require(notEntered, "Shell/re-entered");
        notEntered = false;
        _;
        notEntered = true;
 
    }

    modifier transactable () {

        require(!frozen, "Shell/frozen-only-allowing-proportional-withdraw");
        _;

    }

    modifier unpartitioned () {

        require(!partitioned, "Shell/pool-partitioned");
        _;

    }

    modifier deadline (uint _deadline) {

        require(block.timestamp < _deadline, "Shell/tx-deadline-passed");
        _;

    }


    constructor () public {

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        shell.testHalts = true;

    }

    function setParams (uint _alpha, uint _beta, uint _epsilon, uint _max, uint _lambda) external onlyOwner {

        maxFee = Controller.setParams(shell, _alpha, _beta, _epsilon, _max, _lambda);

    }

    function includeAsset (address _numeraire, address _nAssim, address _reserve, address _rAssim, uint _weight) external onlyOwner {

        Controller.includeAsset(shell, numeraires, _numeraire, _nAssim, _reserve, _rAssim, _weight);

    }

    function includeAssimilator (address _numeraire, address _derivative, address _assimilator) external onlyOwner {

        Controller.includeAssimilator(shell, _numeraire, _derivative, _assimilator);

    }

    function excludeAssimilator (address _assimilator) external onlyOwner {

        delete shell.assimilators[_assimilator];

    }

    function freeze (bool _toFreezeOrNotToFreeze) external onlyOwner {

        emit SetFrozen(_toFreezeOrNotToFreeze);
        frozen = _toFreezeOrNotToFreeze;

    }

    function transferOwnership (address _newOwner) external onlyOwner {
<<<<<<< HEAD
=======

>>>>>>> libraries
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;

    }

    function prime () external {

        Controller.prime(shell);

    }

    function swapByOrigin (
        address _origin,
        address _target,
        uint _oAmt,
        uint _minTAmt,
        uint _dline
    ) external deadline(_dline) transactable nonReentrant returns (
        uint tAmt_
    ) {

        tAmt_ = Swaps.originSwap(shell, _origin, _target, _oAmt, msg.sender);

        require(tAmt_ > _minTAmt, "Shell/below-min-target-amount");

    }

    function transferByOrigin (
        address _origin,
        address _target,
        uint _oAmt,
        uint _minTAmt,
        uint _dline,
        address _rcpnt
    ) external deadline(_dline) transactable nonReentrant returns (
        uint tAmt_
    ) {

        tAmt_ = Swaps.originSwap(shell, _origin, _target, _oAmt, _rcpnt);

        require(tAmt_ > _minTAmt, "Shell/below-min-target-amount");

    }

    function viewOriginSwap (
        address _origin,
        address _target,
        uint _oAmt
    ) external view transactable returns (
        uint tAmt_
    ) {

        tAmt_ = Swaps.viewOriginSwap(shell, _origin, _target, _oAmt);

    }


    // / @author james foley http://github.com/realisation
    // / @notice swap a dynamic origin amount for a fixed target amount
    // / @param _origin the address of the origin
    // / @param _target the address of the target
    // / @param _mOAmt the maximum origin amount
    // / @param _tAmt the target amount
    // / @param _dline deadline in block number after which the trade will not execute
    // / @return oAmt_ the amount of origin that has been swapped for the target
    function swapByTarget (
        address _origin,
        address _target,
        uint _maxOAmt,
        uint _tAmt,
        uint _dline
    ) external deadline(_dline) transactable nonReentrant returns (
        uint oAmt_
    ) {

        oAmt_ = Swaps.targetSwap(shell, _origin, _target, _tAmt, msg.sender);

        require(oAmt_ < _maxOAmt, "Shell/above-max-origin-amount");

    }

    // / @author james foley http://github.com/realisation
    // / @notice transfer a dynamic origin amount into a fixed target amount at the recipients address
    // / @param _origin the address of the origin
    // / @param _target the address of the target
    // / @param _mOAmt the maximum origin amount
    // / @param _tAmt the target amount
    // / @param _dline deadline in block number after which the trade will not execute
    // / @param _rcpnt the address of the recipient of the target
    // / @return oAmt_ the amount of origin that has been swapped for the target
    function transferByTarget (
        address _origin,
        address _target,
        uint _maxOAmt,
        uint _tAmt,
        uint _dline,
        address _rcpnt
    ) external deadline(_dline) transactable nonReentrant returns (uint oAmt_) {

        oAmt_ = Swaps.targetSwap(shell, _origin, _target, _tAmt, _rcpnt);

        require(oAmt_ < _maxOAmt, "Shell/above-max-origin-amount");

    }

    // / @author james foley http://github.com/realisation
    // / @notice view how much of the origin currency the target currency will take
    // / @param _origin the address of the origin
    // / @param _target the address of the target
    // / @param _tAmt the target amount
    // / @return oAmt_ the amount of target that has been swapped for the origin
    function viewTargetSwap (
        address _origin,
        address _target,
        uint _tAmt
    ) external view transactable returns (
        uint oAmt_
    ) {

        oAmt_ = Swaps.viewTargetSwap(shell, _origin, _target, _tAmt);

    }

    // / @author james foley http://github.com/realisation
    // / @notice selectively deposit any supported stablecoin flavor into the contract in return for corresponding amount of shell tokens
    // / @param _flvrs an array containing the addresses of the flavors being deposited into
    // / @param _amts an array containing the values of the flavors you wish to deposit into the contract. each amount should have the same index as the flavor it is meant to deposit
    // / @param _minShells minimum acceptable amount of shells
    // / @param _dline deadline for tx
    // / @return shellsToMint_ the amount of shells to mint for the deposited stablecoin flavors
    function selectiveDeposit (
        address[] calldata _flvrs,
        uint[] calldata _amts,
        uint _minShells,
        uint _dline
    ) external deadline(_dline) transactable nonReentrant returns (
        uint shells_
    ) {

        shells_ = SelectiveLiquidity.selectiveDeposit(shell, _flvrs, _amts, _minShells);

    }

    // / @author james folew http://github.com/realisation
    // / @notice view how many shell tokens a deposit will mint
    // / @param _flvrs an array containing the addresses of the flavors being deposited into
    // / @param _amts an array containing the values of the flavors you wish to deposit into the contract. each amount should have the same index as the flavor it is meant to deposit
    // / @return shellsToMint_ the amount of shells to mint for the deposited stablecoin flavors
    function viewSelectiveDeposit (
        address[] calldata _flvrs,
        uint[] calldata _amts
    ) external view transactable returns (
        uint shells_
    ) {

        shells_ = SelectiveLiquidity.viewSelectiveDeposit(shell, _flvrs, _amts);

    }

    // / @author james foley http://github.com/realisation
    // / @notice deposit into the pool with no slippage from the numeraire assets the pool supports
    // / @param  _deposit the full amount you want to deposit into the pool which will be divided up evenly amongst the numeraire assets of the pool
    // / @return shellsToMint_ the amount of shells you receive in return for your deposit
    function proportionalDeposit (
        uint _deposit,
        uint _dline
    ) external deadline(_dline) transactable nonReentrant returns (
        uint shells_,
        uint[] memory
    ) {

        return ProportionalLiquidity.proportionalDeposit(shell, _deposit);

    }

    function viewProportionalDeposit (
        uint _deposit,
        uint _dline
    ) external view deadline(_dline) transactable returns (
        uint shells_,
        uint[] memory
    ) {

        return ProportionalLiquidity.viewProportionalDeposit(shell, _deposit);

    }

    // / @author james foley http://github.com/realisation
    // / @notice selectively withdrawal any supported stablecoin flavor from the contract by burning a corresponding amount of shell tokens
    // / @param _flvrs an array of flavors to withdraw from the reserves
    // / @param _amts an array of amounts to withdraw that maps to _flavors
    // / @return shellsBurned_ the corresponding amount of shell tokens to withdraw the specified amount of specified flavors
    function selectiveWithdraw (
        address[] calldata _flvrs,
        uint[] calldata _amts,
        uint _maxShells,
        uint _dline
    ) external deadline(_dline) transactable nonReentrant returns (
        uint shells_
    ) {

        shells_ = SelectiveLiquidity.selectiveWithdraw(shell, _flvrs, _amts, _maxShells);

    }

    // / @author james foley http://github.com/realisation
    // / @notice view how many shell tokens a withdraw will consume
    // / @param _flvrs an array of flavors to withdraw from the reserves
    // / @param _amts an array of amounts to withdraw that maps to _flavors
    // / @return shellsBurned_ the corresponding amount of shell tokens to withdraw the specified amount of specified flavors
    function viewSelectiveWithdraw (
        address[] calldata _flvrs,
        uint[] calldata _amts
    ) external view transactable returns (
        uint shells_
    ) {

        shells_ = SelectiveLiquidity.viewSelectiveWithdraw(shell, _flvrs, _amts);

    }

    // / @author  james foley http://github.com/realisation
    // / @notice  withdrawas amount of shell tokens from the the pool equally from the numeraire assets of the pool with no slippage
    // / @param   _withdrawal the full amount you want to withdraw from the pool which will be withdrawn from evenly amongst the numeraire assets of the pool
    function proportionalWithdraw (
        uint _withdrawal,
        uint _dline
    ) external deadline(_dline) unpartitioned nonReentrant returns (
        uint[] memory
    ) {

        return ProportionalLiquidity.proportionalWithdraw(shell, _withdrawal);

    }

    function viewProportionalWithdraw (
        uint _withdrawal
    ) external view unpartitioned returns (
        uint[] memory
    ) {

        return ProportionalLiquidity.viewProportionalWithdraw(shell, _withdrawal);

    }

    function partition () external onlyOwner {

        require(frozen, "Shell/pool-is-not-frozen");

        partitioned = true;

        PartitionedLiquidity.partition(shell, partitionTickets);

    }

    function partitionedWithdraw (
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external returns (
        uint256[] memory withdraws_
    ) {

        require(partitioned, "Shell/pool-is-not-partitioned");

        return PartitionedLiquidity.partitionedWithdraw(shell, partitionTickets, _tokens, _amounts);

    }

    function viewPartitionClaims (
        address _addr
    ) external view returns (
        uint[] memory
    ) {

        require(partitioned, "Shell/not-partitioned");

        return PartitionedLiquidity.viewPartitionClaims(shell, partitionTickets, _addr);

    }

    function transfer (address _recipient, uint _amount) public nonReentrant returns (bool) {

        return Shells.transfer(shell, _recipient, _amount);

    }

    function transferFrom (address _sender, address _recipient, uint _amount) public nonReentrant returns (bool) {
        // return shell.transferFrom(_sender, _recipient, _amount);
    }

    function approve (address _spender, uint _amount) public nonReentrant returns (bool success_) {
        // return shell.approve(_spender, _amount);
    }

    function increaseAllowance(address _spender, uint _addedValue) public returns (bool success_) {
        // return shell.increaseAllowance(_spender, _addedValue);
    }

    function decreaseAllowance(address _spender, uint _subtractedValue) public returns (bool success_) {
        // return shell.decreaseAllowance(_spender, _subtractedValue);
    }

    function balanceOf (address _account) public view returns (uint) {
        return shell.balances[_account];
    }

    function totalSupply () public view returns (uint totalSupply_) {
        totalSupply_ = shell.totalSupply;
    }

    function allowance (address _owner, address _spender) public view returns (uint) {
        return shell.allowances[_owner][_spender];
    }

    function liquidity () public returns (uint, uint[] memory) {

        return Liquidity.liquidity(shell);

    }

    function TEST_setTestHalts (bool toTestOrNotToTest) public {

        shell.testHalts = toTestOrNotToTest;

    }

    event log(bytes32);
    event log_addr(bytes32, address);
    event log_uint(bytes32, uint);
    event log_uints(bytes32, uint[]);
    event log_ints(bytes32, int[]);

    function TEST_safeApprove (address _token, address _spender, uint _value) public onlyOwner {

        (bool success, bytes memory returndata) = _token.call(abi.encodeWithSignature("approve(address,uint256)", _spender, _value));

        require(success, "SafeERC20: low-level call failed");

    }

    IERC20 dai;
    IERC20 usdc;
    IERC20NoBool usdt;
    IERC20 susd;

    function TEST_includeAssimilatorState(IERC20 _dai, ICToken _cdai, IChai _chai, IPot _pot, IERC20 _usdc, ICToken _cusdc, IERC20NoBool _usdt, IAToken _ausdt, IERC20 _susd, IAToken _asusd) public {
        dai = _dai; cdai = _cdai; chai = _chai; pot = _pot;
        usdc = _usdc; cusdc = _cusdc;
        usdt = _usdt; ausdt = _ausdt;
        susd = _susd; asusd = _asusd;
    }

}
