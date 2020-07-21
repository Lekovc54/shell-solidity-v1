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
import "./Assimilators.sol";

import "./ShellMath.sol";

import "./Loihi.sol";

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library Controller {

    int128 constant ONE = 0x10000000000000000;

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    using Assimilators for address;

    event ParametersSet(uint256 alpha, uint256 beta, uint256 delta, uint256 epsilon, uint256 lambda);

    function setParams (
        Loihi.Shell storage shell,
        uint256 _alpha,
        uint256 _beta,
        uint256 _max,
        uint256 _epsilon,
        uint256 _lambda
    ) internal returns (uint256 max_) {

        require(_max <= .5e18, "Shell/parameter-invalid-max");

        int128 _gLiq;
        int128[] memory _bals = new int128[](shell.reserves.length);

        for (uint i = 0; i < _bals.length; i++) {

            int128 _bal = Assimilators.viewNumeraireBalance(shell.reserves[i].addr);

            _bals[i] = _bal;

            _gLiq += _bal;

        }

        shell.alpha = _alpha.divu(1e18);
        shell.beta = _beta.divu(1e18);
        shell.delta = _max.divu(1e18).div(uint(2).fromUInt().mul(shell.alpha.sub(shell.beta)));
        shell.epsilon = _epsilon.divu(1e18);
        if (shell.epsilon.mulu(1e18) < _epsilon) shell.epsilon = shell.epsilon.add(uint(1).divu(1e18));
        shell.lambda = _lambda.divu(1e18);

        require(shell.alpha < ONE && shell.alpha > 0, "Shell/parameter-invalid-alpha");
        require(shell.beta <= shell.alpha && shell.beta >= 0, "Shell/parameter-invalid-beta");
        require(shell.epsilon >= 0 && _epsilon < 1e16, "Shell/parameter-invalid-epsilon");
        require(shell.lambda >= 0 && shell.lambda <= ONE, "Shell/parameter-invalid-lambda");

        int128 _psi = ShellMath.calculateFee(_gLiq, _bals, shell.beta, shell.delta, shell.weights);

        require(shell.omega >= _psi, "Shell/paramter-invalid-psi");

        shell.omega = _psi;

        emit ParametersSet(_alpha, _beta, shell.delta.mulu(1e18), _epsilon, _lambda);

        max_ = _max;

    }

    function includeAsset (
        Loihi.Shell storage shell,
        address[] storage numeraires,
        address _numeraire,
        address _numeraireAssim,
        address _reserve,
        address _reserveAssim,
        uint256 _weight
    ) internal {

        require(_numeraire != address(0), "Shell/numeraire-cannot-be-zeroth-adress");
        require(_numeraireAssim != address(0), "Shell/numeraire-assimilator-cannot-be-zeroth-adress");
        require(_reserve != address(0), "Shell/reserve-cannot-be-zeroth-adress");
        require(_reserveAssim != address(0), "Shell/reserve-assimilator-cannot-be-zeroth-adress");
        require(_weight < 1e18, "Shell/weight-must-be-less-than-one");

        numeraires.push(_numeraire);

        Loihi.Assimilator storage _numeraireAssimilator = shell.assimilators[_numeraire];

        _numeraireAssimilator.addr = _numeraireAssim;

        _numeraireAssimilator.ix = uint8(shell.numeraires.length);

        shell.numeraires.push(_numeraireAssimilator);

        Loihi.Assimilator storage _reserveAssimilator = shell.assimilators[_reserve];

        _reserveAssimilator.addr = _reserveAssim;

        _reserveAssimilator.ix = uint8(shell.reserves.length);

        shell.reserves.push(_reserveAssimilator);

        int128 __weight = _weight.divu(1e18).add(uint256(1).divu(1e18));

        shell.weights.push(__weight);

    }

    function includeAssimilator (
        Loihi.Shell storage shell,
        address _numeraire,
        address _derivative,
        address _assimilator
    ) internal {

        require(_numeraire != address(0), "Shell/numeraire-cannot-be-zeroth-address");
        require(_derivative != address(0), "Shell/derivative-cannot-be-zeroth-address");
        require(_assimilator != address(0), "Shell/assimilator-cannot-be-zeroth-address");

        Loihi.Assimilator storage _numeraireAssim = shell.assimilators[_numeraire];

        shell.assimilators[_derivative] = Loihi.Assimilator(_assimilator, _numeraireAssim.ix);

    }

    function prime (
        Loihi.Shell storage shell
    ) internal {

        uint _length = shell.reserves.length;
        int128 _oGLiq;
        int128[] memory _oBals = new int128[](_length);

        for (uint i = 0; i < _length; i++) {
            int128 _bal = shell.reserves[i].addr.viewNumeraireBalance();
            _oGLiq += _bal;
            _oBals[i] = _bal;
        }

        shell.omega = ShellMath.calculateFee(_oGLiq, _oBals, shell.beta, shell.delta, shell.weights);

    }

}