//SPDX-License-Identifer: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
//import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants{
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;

    uint96 public constant BASE_FEE = 0.1 ether;
    uint96 public constant GAS_PRICE = 1e9; // 1 gwei
    int256 public constant WEI_PER_UNIT_LINK = 1e18; // 1 LINK = 10^18 wei



}

contract HelperConfig is CodeConstants, Script{

    error HelperConfig__InvalidChainId();
    struct NetworkConfig{
        address vrfCoordinator;
       // address linkToken;
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint256 entryFee;
        address account;
    }

    mapping(uint256 => NetworkConfig) public networkConfigs;

    NetworkConfig public localNetworkConfig;

    constructor(){
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getActiveNetworkConfig(uint256 chainId) public view returns (NetworkConfig memory){
        if(networkConfigs[chainId].vrfCoordinator != address(0)){
            return networkConfigs[chainId];
        } else if (chainId == ANVIL_CHAIN_ID){
                return getOrCreateAnvilEthConfig();

            } else {
                revert HelperConfig__InvalidChainId();
            }

        }

    function getConfig() public view returns(NetworkConfig memory){
       return getActiveNetworkConfig(block.chainid);
    }
    



    function getSepoliaEthConfig() internal view returns(NetworkConfig memory){
        return NetworkConfig({
         vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
         //linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
         keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
         subscriptionId: 0,
         callbackGasLimit: 500000,
         entryFee: 0.1 ether,
         account: msg.sender

        });
    }

    function getOrCreateAnvilEthConfig() external view returns(NetworkConfig memory){
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;


        }

        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(

            BASE_FEE,
            GAS_PRICE,
            WEI_PER_UNIT_LINK

        );
        //LinkToken linkToken = new LinkToken();

        localNetworkConfig = NetworkConfig({
            vrfCoordinator: address(vrfCoordinatorMock),
           // linkToken: address(linkToken),
            keyHash: 0x6c3699283bda56ad74f6b855546325b68d482e984b2f4a8a7c5d9c1e2d3e4f5a,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            entryFee: 0.1 ether,
            account: msg.sender
        });

        return localNetworkConfig;
    }

}



