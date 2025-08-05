//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CoinFlip} from "../src/CoinFlip.sol";

contract Deploy is Script, HelperConfig {
    CoinFlip public coinFlip;
    HelperConfig  public helperconfig;

    function run() external{

    }

    function deployCoinFlip() public returns (CoinFlip, HelperConfig){

        helperconfig = new HelperConfig();

        HelperConfig.NetworkConfig memory activeConfig = helperConfig.getConfig();

        vm.startBroadcast();

        coinFlip = new CoinFlip(
            activeConfig.vrfCoordinator,
            activeConfig.linkToken,
            activeConfig.keyHash,
            activeConfig.subscriptionId,
            activeConfig.callbackGasLimit,
            activeConfig.entryFee
        );

        vm.stopBroadcast();

        return(coinFlip, helperconfig);
    }
}