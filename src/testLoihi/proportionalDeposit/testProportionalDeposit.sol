pragma solidity ^0.5.6;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "ds-test/test.sol";
import "ds-math/math.sol";
import "../flavorsSetup.sol";
import "../adaptersSetup.sol";
import "../../Loihi.sol";
import "../../adapters/kovan/kovanCUsdcAdapter.sol";
import "../../adapters/kovan/kovanCDaiAdapter.sol";


contract LoihiTest is AdaptersSetup, DSMath, DSTest {
    Loihi l;

    function setUp() public {

        setupFlavors();
        setupAdapters();
        l = new Loihi(chai, cdai, dai, pot, cusdc, usdc, usdt);
        approveFlavors(address(l));
        
        // setupFlavors();
        // setupAdapters();
        // l = new Loihi(address(0), address(0), address(0), address(0), address(0), address(0), address(0));
        // approveFlavors(address(l));

        uint256 weight = WAD / 3;

        l.includeNumeraireAndReserve(dai, cdaiAdapter);
        l.includeNumeraireAndReserve(usdc, cusdcAdapter);
        l.includeNumeraireAndReserve(usdt, usdtAdapter);

        l.includeAdapter(chai, chaiAdapter, cdaiAdapter, weight);
        l.includeAdapter(dai, daiAdapter, cdaiAdapter, weight);
        l.includeAdapter(cdai, cdaiAdapter, cdaiAdapter, weight);
        l.includeAdapter(cusdc, cusdcAdapter, cusdcAdapter, weight);
        l.includeAdapter(usdc, usdcAdapter, cusdcAdapter, weight);
        l.includeAdapter(usdt, usdtAdapter, usdtAdapter, weight);


    }

    function testproportionalDeposit () public {

        uint256 mintedShells = l.proportionalDeposit(100 * (10 ** 18));
        // uint256 balance = l.balanceOf(address(this));
        // emit log_named_uint("minted shells", mintedShells);
        // emit log_named_uint("balance", balance);
        emit log_named_uint("cusdc", IERC20(cusdc).balanceOf(address(l))); // 165557372275
        emit log_named_uint("cdai", IERC20(cdai).balanceOf(address(l))); // 163925889326
        emit log_named_uint("usdt", IERC20(usdt).balanceOf(address(l))); // 33333333333333333300

        new KovanCUsdcAdapter().getNumeraireAmount(165557372275);
        new KovanCDaiAdapter().getNumeraireAmount(163925889326);

        // uint256 mintedShells2 = l.proportionalDeposit(50 * (10 ** 18));
        // uint256 balance2 = l.balanceOf(address(this));
        // // emit log_named_uint("mintedShells2", mintedShells2);
        // // emit log_named_uint("balance2", balance2);

        // uint256 mintedShells3 = l.proportionalDeposit(70 * (10 ** 18));
        // uint256 balance3 = l.balanceOf(address(this));
        // // emit log_named_uint("mintedShells2", mintedShells3);
        // // emit log_named_uint("balance2", balance3);
        // // assertTrue(false);

    }

    // function testSelectiveDeposit () public {

    //     uint256[] memory deposits = new uint256[](3);
    //     deposits[0] = 250;
    //     deposits[1] = 250;
    //     deposits[2] = 500;

    //     address[] memory flavors = new address[](3);
    //     flavors[0] = chai;
    //     flavors[1] = cusdc;
    //     flavors[2] = usdt;

    //     l.selectiveDeposit(flavors, deposits);

    // }

}