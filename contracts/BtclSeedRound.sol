// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./utils/GSN/Context.sol";
import "./utils/token/ERC677/ERC677Receiver.sol";
import "./utils/token/ERC677/ERC677.sol";
import "./utils/util/ReentrancyGuard.sol";
import "./utils/chainlink/AggregatorV3Interface.sol";
import "./utils/token/ERC677/IERC677.sol";
import "./utils/util/Address.sol";
import "./utils/token/ERC677/SafeERC677.sol";
import "./utils/chainlink/vendor/SafeMathChainlink.sol";

// ETH MAINNET     
// PAIRS     DECIMALS               TOKENS                                 CHAINLINK PRICE FEED                            UNLOCKED ADDRESS
// WBTC / USD	8	0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599   0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c   0xD41CdB2A35a666e8e1F9F53054e85091b67E13Af
// WETH / USD	8	0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2   0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419   0x4d5c38f655580641794f42eadf1abc2a54ecb236
// LINK / USD	8	0xB8c77482e45F1F44dE1745F52C74426C631bDD52   0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c   0x514910771AF9Ca656af840dff83E8264EcF986CA
//  BNB / USD	8	0x514910771AF9Ca656af840dff83E8264EcF986CA   0x14e613AC84a31f709eadbdF89C6CC390fDc9540A   0xd88B55467f58af508dBfDC597E8Ebd2Ad2De49b3
//  UNI / USD	8	0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984   0x553303d460EE0afB37EdFf9bE42922D8FF63220e   0x878f0822A9e77c1dD7883E543747147Be8D63C3B
//  DAI / USD	8	0x6B175474E89094C44Da98b954EedeAC495271d0F   0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9   0x5A16552f59ea34E44ec81E58b3817833E9fD5436
// USDC / USD	8	0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48   0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6   0xAe2D4617c862309A3d75A0fFB358c7a5009c673F
// USDT / USD	8	0xdAC17F958D2ee523a2206206994597C13D831ec7   0x3E7d1eAB13ad0104d2750B8863b489D65364e32D   0xA7A93fd0a276fc1C0197a5B5623eD117786eeD06

// ETH KOVAN - CUSTOM CREATED TOKENS THAT MIMIC ORIGINAL TOKEN
// "NLL",  "NLL",  18, 1000000  0xD4825A27Ca43Ad5f089e3b7aAc93078C100698E0
// "BTCL", "BTCL", 18, 10000000 0xc41B5fC87CB08b7C96db7F7d5c83C5729A5c6634
// "WBTC", "WBTC",  8, 1000000  0x9Bf27E57245DD4232C018f2097b1e999A7161a3B
// "WETH", "WETH", 18, 1000000  0x8ee34E67763cE078Ffced75B3F6A5ac151f5Db33
// "Link", "LINK", 18, 1000000  0xa36085F69e2889c224210F603D836748e7dC0088 address created by ChainLink Team on KOVAN
// "BNB",  "BNB",  18, 1000000  0x4260931D230F7a66691aBbFe9aaFb25B2F5B55A8
// "UNI",  "UNI",  18, 1000000  0x2dE19249451741935003E1BF819E0dBb3010463d
// "DAI",  "DAI",  18, 1000000  0xb3A570feDE54326Aa5Cc66D6C03bC3c72A6E4C86
// "USDC", "USDC",  6, 1000000  0xFfA962796FC63611f8bCc53Fbb24CbA1CB53b273
// "USDT", "USDT",  6, 1000000  0xDc3d34839ba29c76FA295640CE3A07b77FfA8AD9

// ETH KOVAN - CHAINLINK PRICE FEED 8 DECIMALS IN USD
// PAIRS     DECIMALS               TOKENS                                 CHAINLINK PRICE FEED                            UNLOCKED ADDRESS
// WBTC / USD	8	0x9Bf27E57245DD4232C018f2097b1e999A7161a3B   0x6135b13325bfC4B00278B4abC5e20bbce2D6580e   0xD41CdB2A35a666e8e1F9F53054e85091b67E13Af
// WETH / USD	8	0x8ee34E67763cE078Ffced75B3F6A5ac151f5Db33   0x9326BFA02ADD2366b30bacB125260Af641031331   0x4d5c38f655580641794f42eadf1abc2a54ecb236
// LINK / USD	8	0xa36085F69e2889c224210F603D836748e7dC0088   0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0   0x514910771AF9Ca656af840dff83E8264EcF986CA
//  BNB / USD	8	0x4260931D230F7a66691aBbFe9aaFb25B2F5B55A8   0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16   0xd88B55467f58af508dBfDC597E8Ebd2Ad2De49b3
//  UNI / USD	8	0x2dE19249451741935003E1BF819E0dBb3010463d   0xDA5904BdBfB4EF12a3955aEcA103F51dc87c7C39   0x878f0822A9e77c1dD7883E543747147Be8D63C3B
//  DAI / USD	8	0xb3A570feDE54326Aa5Cc66D6C03bC3c72A6E4C86   0x777A68032a88E5A84678A77Af2CD65A7b3c0775a   0x5A16552f59ea34E44ec81E58b3817833E9fD5436
// USDC / USD	8	0xFfA962796FC63611f8bCc53Fbb24CbA1CB53b273   0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60   0xAe2D4617c862309A3d75A0fFB358c7a5009c673F
// USDT / USD	8	0xDc3d34839ba29c76FA295640CE3A07b77FfA8AD9   0x2ca5A90D34cA333661083F89D831f757A9A50148   0xA7A93fd0a276fc1C0197a5B5623eD117786eeD06

contract BtclSeedRound is Context, ReentrancyGuard {
    using SafeMathChainlink for uint256;
    using SafeERC677 for IERC677;

    event TokensPurchased(address purchaser, uint256 btclAmount, uint256 amount);
    event DepositedTokens(address from, uint256 value, bytes data);

    IERC677 public immutable btclToken;
    address payable public wallet;
    
    struct UserInfo {
        uint256 totalLockedBTCL;      // Total BTCL Tokens left to be released
        uint256 totalClaimedBTCL;     // Total BTCL Tokens Claimed
        uint256 totalUSDContributed;  // Total USD Contribution in decimals
        uint256 totalContributions;   // Total Number of Token Contributions
        uint256 lastRewardBlock;      // Last Block when Tokens were Claimed
    }
    
    struct UserContribution {
        address token;                // Individual Token Address
        uint256 time;                 // Individual Contribution Timestamp
        uint256 tokenInUSD;           // Individual Token USD Value
        uint256 tokenAmount;          // Individual Token Contribution
        uint256 btclToDistribute;     // Individual BTCL Tokens to be distributed
    }
    
    uint256 public btclDistributed;
    uint256 public totalRaised;
    uint256 public kycUsdLimit = 1500000; // Max Contribution $15K with 2 extra decimals for precision
    uint256 public kycLimitUplifted = 5000000; // Max Contribution $50K with 2 extra decimals for precision
    uint256 public blocksPerMonth = 206615;
    uint256 public startBlock = 13230000; // https://etherscan.io/block/countdown/13230000 (14 Sep 2021)
    uint256 public endBlock = 13840000; // https://etherscan.io/block/countdown/13840000 (15 Dec 2021)
    uint256 public cliffEndingBlock = 14580000; // https://etherscan.io/block/countdown/14645000 (15 April 2022)
    uint256[12] public vestingSchedules;
    uint256[12] public vestingPercentages = [24,5,5,5,5,5,5,5,5,12,12,12];
    
    mapping(address => bool) private kyc;
    mapping(address => bool) private kycUplifted;
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public totalContributions;
    mapping(address => mapping(uint256 => UserContribution)) public userContribution;
    mapping(address => mapping(uint256 => uint256)) public totalBTCL; // Total BTCL Tokens released each stage
    mapping(address => address) public tokensAndFeeds;
    
    modifier onlyTeam() {
        require(wallet == _msgSender(), "Only the team wallet can run this function");
        _;
    }
    
    // TOKENS AND PRICE FEEDS
    // 0, 0, 0, 0, 0xc41B5fC87CB08b7C96db7F7d5c83C5729A5c6634, ["0x9Bf27E57245DD4232C018f2097b1e999A7161a3B", "0x8ee34E67763cE078Ffced75B3F6A5ac151f5Db33", "0xa36085F69e2889c224210F603D836748e7dC0088", "0x4260931D230F7a66691aBbFe9aaFb25B2F5B55A8", "0x2dE19249451741935003E1BF819E0dBb3010463d", "0xb3A570feDE54326Aa5Cc66D6C03bC3c72A6E4C86", "0xFfA962796FC63611f8bCc53Fbb24CbA1CB53b273", "0xDc3d34839ba29c76FA295640CE3A07b77FfA8AD9"], ["0x6135b13325bfC4B00278B4abC5e20bbce2D6580e", "0x9326BFA02ADD2366b30bacB125260Af641031331", "0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0", "0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16", "0xDA5904BdBfB4EF12a3955aEcA103F51dc87c7C39", "0x777A68032a88E5A84678A77Af2CD65A7b3c0775a", "0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60", "0x2ca5A90D34cA333661083F89D831f757A9A50148"]
    constructor(uint256 _startBlock, uint256 _endBlock, uint256 _cliffEndingBlock, uint256 _blocksPerMonth, address _btclToken, IERC677[] memory assets, address[] memory priceOracles) public {
        btclToken = IERC677(_btclToken);
        wallet = _msgSender();
        
        startBlock = _startBlock == 0 ? block.number : _startBlock;
        endBlock = _endBlock == 0 ? block.number + 15 : _endBlock;
        cliffEndingBlock = _cliffEndingBlock == 0 ? block.number + 20 : _cliffEndingBlock;
        blocksPerMonth = _blocksPerMonth == 0 ? 5 : _blocksPerMonth;
        
        for(uint256 i = 0; i < priceOracles.length; i++) {
            tokensAndFeeds[address(assets[i])] = priceOracles[i];
        }
        
        for(uint256 i = 0; i < vestingPercentages.length; i++) {
            vestingSchedules[i] = cliffEndingBlock.add(blocksPerMonth.mul(i));
        }
    }
    
    /*
     * Aggregate the value for whitelisted tokens.
     * @param _asset the token to be contributed.
     * @param _amount the amount of the token contribution.
     * @return totalUSD and toContribute and toDistribute 
     */
    function getTokenExchangeRate(address _asset, uint256 _amount) public view returns (uint256 totalUSD, uint256 toContribute, uint256 toDistribute) {
        require(_asset != address(0) && tokensAndFeeds[_asset] != address(0), "Asset must be whitelisted and cannot be address(0)");
        
        (, int256 price_token, , , ) = AggregatorV3Interface(tokensAndFeeds[_asset]).latestRoundData();
        (, int256 price_dai, , , ) = AggregatorV3Interface(0x777A68032a88E5A84678A77Af2CD65A7b3c0775a).latestRoundData();

        if(_asset == 0xDc3d34839ba29c76FA295640CE3A07b77FfA8AD9 || _asset == 0xFfA962796FC63611f8bCc53Fbb24CbA1CB53b273) { // usdt & usdc
            totalUSD = _amount.mul(100); // with 2 decimals precission
            toContribute = _amount.mul(1000000);
            toDistribute = _amount.mul(66666666666666666666);
        } else if (_asset == 0xb3A570feDE54326Aa5Cc66D6C03bC3c72A6E4C86) { // dai
            totalUSD = _amount.mul(100); // with 2 decimals precission
            toContribute = _amount.mul(1000000000000000000);
            toDistribute = _amount.mul(66666666666666666666);
        } else {
            uint256 tokenDecimals = uint256(10 ** uint256(IERC677(_asset).decimals()));
            uint256 tokenValueInUSD = uint256(price_token).div(uint256(price_dai));
            uint256 tokenOneDollarWorth = tokenDecimals.div(tokenValueInUSD);
            totalUSD = _amount.mul(100).div(tokenOneDollarWorth); // USD with 2 extra decimals
            toContribute = _amount;
            toDistribute = totalUSD.mul(66666666666666666666).div(100); // 1$ = 66.6 BTCL
        }
    }
    
    
    
    /*
     * Contribute any of the 8 Whitelisted Tokens (WBTC/WETH/LINK/BNB/UNI/DAI/USDC/USDT).
     * @param _asset the token used to make the contribution.
     * @param _value the value to be contributed.
     * @return success Contribution succeeded or failed.
     */
    function buyTokens(address _asset, uint256 _value) public nonReentrant returns (bool success) {
        require(block.number >= startBlock && block.number <= endBlock && btclDistributed < 250000000 * 1e18,"Seed Round finished successfully. Congrats to everyone!");
        require(kyc[_msgSender()] == true, "Only Whitelisted addresses are allowed to participate in the Seed Round.");

        (uint256 totalUSD, uint256 toContribute, uint256 toDistribute) = getTokenExchangeRate(_asset, _value);
        require(totalUSD >= 10000, "Contribution amount must be atleast 100$ and max 50K USD worth."); // 100$ with 2 decimals precission
        
        _createPayment(_msgSender(), _asset, totalUSD, toContribute, toDistribute);
    
        return true;
    }
    
    /*
     * Helper function to create the contribution and set BTCL Token Vesting & Distribution Emissions.
     * @param beneficiary The address of the Contributor.
     * @param asset The token used to Contribute.
     * @param value The total amount in USD Contributed.
     */
    function _createPayment(address _beneficiary, address _asset, uint256 _value, uint256 toContribute, uint256 toDistribute) private {

        makeTokenContribution(_beneficiary, _asset, toContribute, _value);
        
        splitTokensInStages(toDistribute);
        
        hydrateContribution(_beneficiary, _asset, toContribute, toDistribute, _value); 
        
        // EMIT & RETURN TRUE IF CONTRIBUTION SUCCEEDED
        emit TokensPurchased(_beneficiary, toDistribute, _value);
    }
    
    /**
     * Helper function that checks token allowance and makes the contribution.
     * @param _beneficiary the address of the contributor.
     * @param _asset the asset used to contribute.
     * @param _toContribute the amount contributed.
     */
    function makeTokenContribution(address _beneficiary, address _asset, uint256 _toContribute, uint256 _value) private {
        UserInfo storage user = userInfo[_beneficiary];
        
        // CHECK IF 15K OR 50K UPLIFTED KYC LIMIT HAS BEEN REACHED 
        uint256 newUSDValue = user.totalUSDContributed.add(_value);
        
        if(kyc[_beneficiary] == true) {
            if(kycUplifted[_beneficiary] == true) {
                require(newUSDValue <= kycLimitUplifted, "Address can't contribute more than 50K USD.");
            } else {
                require(newUSDValue <= kycUsdLimit, "Address can't contribute more than 15K USD.");    
            }
        }
        
        uint256 allowance = IERC677(_asset).allowance(_beneficiary, address(this));
        require(allowance >= _toContribute, "Check the token allowance");
        
        IERC677(_asset).safeTransferFrom(_beneficiary, wallet, _toContribute);
    }
    
    /**
     * Helper function that split BTCL Tokens into multiple release stages.
     * @param _toDistribute total BTCL Tokens that will be distributed.
     */
    function splitTokensInStages(uint256 _toDistribute) private {
        for(uint256 i = 0; i < vestingPercentages.length; i++) {
            uint256 storedBTCL = totalBTCL[_msgSender()][i];
            uint256 tempBTCL = _toDistribute.mul(vestingPercentages[i]).div(100);
            totalBTCL[_msgSender()][i] = tempBTCL.add(storedBTCL);
        }
    }
    
    /**
     * Helper function that updates individual and global variables.
     * @param _beneficiary the address of the contributor.
     * @param _asset the asset used to contribute.
     * @param _toContribute the amount contributed.
     * @param _toDistribute total BTCL Tokens that will be distributed.
     * @param _value The total amount in USD Contributed.
     */
    function hydrateContribution(address _beneficiary, address _asset, uint256 _toContribute, uint256 _toDistribute, uint256 _value) private {
        UserInfo storage user = userInfo[_beneficiary];
        UserContribution storage contribution = userContribution[_beneficiary][user.totalContributions];
        
        // HYDRATE USER CONTRIBUTION
        user.totalContributions = user.totalContributions.add(1);
        user.totalLockedBTCL = user.totalLockedBTCL.add(_toDistribute);
        user.totalUSDContributed = user.totalUSDContributed.add(_value);
        
        // TOTAL BTCL TO DISTRIBUTE & TOTAL RAISED IN USD
        btclDistributed = btclDistributed.add(_toDistribute);
        totalRaised = totalRaised.add(_value);
        
        // HYDRATE INDIVIDUAL CONTRIBUTION
        totalContributions[_msgSender()] = totalContributions[_msgSender()].add(1);
        contribution.token = _asset;
        contribution.time = now;
        contribution.tokenInUSD = _value;
        contribution.tokenAmount = _toContribute;
        contribution.btclToDistribute = _toDistribute;
    }
    
    /**
     * Claim unlockable BTCL Tokens based on current vesting stage.
     * @return total BTCL tokens claimed.
     */
    function claimVestedTokens() public nonReentrant returns (uint256 total) {
        uint256 totalBtclLeftToWithdraw;
        
        if(block.number > cliffEndingBlock) {
            
            UserInfo storage user = userInfo[_msgSender()];
        
            for(uint256 i = 0; i < vestingSchedules.length; i++) {
                if (block.number >= vestingSchedules[i]) {
                    uint256 tempBTCL = totalBTCL[_msgSender()][i];
                    totalBtclLeftToWithdraw = totalBtclLeftToWithdraw.add(tempBTCL);
                    user.totalClaimedBTCL = user.totalClaimedBTCL.add(tempBTCL);
                    totalBTCL[_msgSender()][i] = 0;
                    user.lastRewardBlock = block.number;
                }
            }
        
            btclToken.safeTransfer(_msgSender(), totalBtclLeftToWithdraw);
        
            return (totalBtclLeftToWithdraw);
        } else {
            revert("The Vesting Cliff Period has not yet passed.");
        }

    }
        
    /**
     * Get tokens unlocked percentage on current stage.
     * @param _contributorAddress the contributor address.
     * @return stage and percent and total Percent of tokens that can be claimed.
     */
    function getTokensUnlockedPercentage(address _contributorAddress) public view returns (uint256 stage, uint256 percentage, uint256 total) {
        uint256 totalLeftToWithdraw;
        uint256 allowedPercent;
        uint256 currentStage;
        
        for (uint8 i = 0; i < vestingSchedules.length; i++) {
            if (block.number >= vestingSchedules[i]) {
                allowedPercent = allowedPercent.add(vestingPercentages[i]);
                currentStage = i;
            }
        }
        
        for(uint256 v = 0; v <= currentStage; v++) {
            if (block.number >= vestingSchedules[currentStage]) {
                uint256 tempBTCL = totalBTCL[_contributorAddress][v];
                totalLeftToWithdraw = totalLeftToWithdraw.add(tempBTCL);
            }
        }
        
        return (currentStage, allowedPercent, totalLeftToWithdraw);
    }

    /**
     * @dev ETH cannot be sent directly. Only WETH is allowed!
     */
    receive() external payable {
        revert("Bitcoin Lottery - Seed Round Contract only accepts Wrapped Ether.");
    }
    
    /**
     * @dev KYC helper function used to display current KYC Status.
     * @param _contributorAddress The Contributor Address Whitelisting Address.
     * @return whitelisted and KYC uplift Status.
     */
    function checkKYC(address _contributorAddress) public view returns (bool whitelisted, bool uplifted) {
        return (kyc[_contributorAddress], kycUplifted[_contributorAddress]);
    }

    /**
     * @dev KYC helper function used by the team to whitelist multiple addresses at once.
     * @param _addresses whitelisted address list.
     * @param _whitelisted whitelisted address can contribute up to $15K.
     * @param _kycUplift whitelisted address sources of funds uplift max contribution up to $50K.
     */
    function multiKycWhitelisting(address[] memory _addresses, bool[] memory _whitelisted, bool[] memory _kycUplift) public onlyTeam returns (bool success) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            kyc[_addresses[i]] = _whitelisted[i];
            kycUplifted[_addresses[i]] = _kycUplift[i];
        }
        return true;
    }
    
    /**
     * @dev LINK helper function used to update old Chainlink Price Feed Aggregators.
     * @param _asset The token associated to the Chainlink Price Feed.
     * @param _newAggregatorAddress The Aggregator Contract Address.
     */
    function updateAggregatorAddress(address _asset, address _newAggregatorAddress) public onlyTeam {
        tokensAndFeeds[_asset] = _newAggregatorAddress;
    }
    
    /**
     * @dev Team helper function used to update old multisig wallet address.
     * @param _newWallet The new team multi signature wallet.
     */
    function updateTeamWalletAddress(address payable _newWallet) public onlyTeam {
        wallet = _newWallet;
    }

    /**
     * @dev ERC677 TokenFallback Function.
     * @param _wallet The team address can send BTCL tokens to the Seed Round Contract.
     * @param _value The amount of tokens sent by the team to the BTCL Seed Round Contract.
     * @param _data  The transaction metadata.
     */
    function onTokenTransfer(address _wallet, uint256 _value, bytes memory _data) public {
        require(_msgSender() == address(btclToken), "Contract only accepts BTCL Tokens");
        require(wallet == _wallet,"Only team wallet is allowed");
        emit DepositedTokens(_wallet, _value, _data);
    }
}
