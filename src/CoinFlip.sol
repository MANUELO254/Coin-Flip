//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

abstract contract CoinGame is VRFConsumerBaseV2Plus{

    event GameEntered (address indexed player, CoinSide prediction);
    event RequestSent(uint256 requestId);
    event WinnerPicked(CoinSide indexed actualResult, CoinSide indexed playerGuess, address player);




    error CoinGame__InsufficientFunds();
    error CoinGame__GameNotOpen();
    error CoinGame__NoPlayers();
    error CoinGame__NoUpKeepNeeded();
    error CoinGame__TransferFailed();





enum GameState{
    OPEN,
    CALCULATING
}

enum CoinSide{
    HEADS,
    TAILS
}
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint256 private immutable i_entryFee;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable [] private s_players;
    CoinSide private s_coinSide;
    GameState private s_gameState;
    uint256 private s_lastTimeStamp;

mapping (address => CoinSide ) private s_playerPredictions;

    constructor(uint256 entryFee, address vrfCoordinator, bytes32 gasLane, uint256 subscriptionId, uint32 callbackGasLimit) 
    VRFConsumerBaseV2Plus(vrfCoordinator){
    i_entryFee = entryFee;
    i_keyHash = gasLane;
    i_subscriptionId = subscriptionId;
    i_callbackGasLimit = callbackGasLimit;
    s_gameState = GameState.OPEN;
    s_lastTimeStamp = block.timestamp;
}

    function enterGame (CoinSide prediction) external payable{
    if(msg.value < i_entryFee){
        revert CoinGame__InsufficientFunds();
    }
    if(s_gameState != GameState.OPEN){
        revert CoinGame__GameNotOpen();
    }
    s_players.push(payable(msg.sender));
    s_playerPredictions[msg.sender] = prediction;

    emit GameEntered (msg.sender, prediction);
}

    function checkUpkeep(bytes memory /* checkData */) public view returns 
        (bool upkeepNeeded, bytes memory /* performData */)
    {
        //checkUpkeep data= players, funds, 
        //performUpkeep data

        bool hasPlayers = s_players.length > 0;
        bool hasFunds = i_entryFee > 0;
        bool isOpen = s_gameState == GameState.OPEN;
        bool timePassed = (block.timestamp - s_lastTimeStamp) > 60;

        upkeepNeeded = hasPlayers && hasFunds && isOpen && timePassed;
        return(upkeepNeeded, "");

    }


    function performUpkeep(bytes calldata /* performData */) external  {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded){
            revert CoinGame__NoUpKeepNeeded();
        }

    s_gameState = GameState.CALCULATING;

                VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

            uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
            emit RequestSent(requestId);

     }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override{
        CoinSide actualResult = CoinSide(randomWords[0] % 2);

        for(uint256 i =0; i<s_players.length; i++){
            address payable player = s_players[i];
            //We want to match each player with their respective guesses
            CoinSide playerGuess = s_playerPredictions[player];
                   if(playerGuess == actualResult){
            (bool sent, ) = player.call{value: i_entryFee * s_players.length}("");
            if(!sent){
                revert CoinGame__TransferFailed();
            }
                emit WinnerPicked(actualResult, playerGuess, player);

        }


    }
    s_players = new address payable[](0);
    s_lastTimeStamp = block.timestamp;
    s_gameState = GameState.OPEN;


}

}