pragma solidity ^ 0.4 .11;

//Contract token is found in its own file. 
//These here are interfaces to access functions and variable of token contract.       
contract token {

    // balance of tokens for individual member
    mapping(address => uint256) public balanceOf;


    // this function creates new tokens and assigns it to the purchaser.
    // It can be only called by the owner of itself or from functions
    // in this contract which is registered with MyToken contract. 

    function mintToken(address target, uint256 mintedAmount);

    function transfer(address target, uint amount);
    function transferFrom(address from, address to, uint amount);
}

// @notice a contract which is inherited by 
// main myBit contract. owned holds several housekeeping functions 
contract owned {
    address public owner;


    /// @notice constructor, sets the owner of the contract
    function owned() {
        owner = msg.sender;
    }

    /// @notice modifier to be used in functions, which can be only called 
    /// by the owner, otherwise call to function will be thrown. 
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    /// @notice used to transfer Ownership
    /// @param newOwner  - new owner of the contract
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;

    }

    /// @dev this function will allow on self destruction of this contract. 
    function kill() {
        if (msg.sender == owner) selfdestruct(owner);
    }
}


/// @dev MyBit contract. Allows new members to be registered and 
/// aquire tokens.
/// Tokens are held in standard token contract defined here. 
contract myBit is owned {


    uint public numMembers;
    uint public numAssetLinks;
    uint public numPorjectContributions;
    // to retrieve a member position in the array without searching for it
    mapping(address => uint) public memberId;

    // list of registered members
    Member[] public members;
    // address of token contract
    token public sharesTokenAddress;
    // total number of tokens in circulation 
    uint public tokensInCirculation;
    // cost of token in wei
    uint public singleTokenCost;
    // list of links between member and asset
    MeberAssetLinked[] public linkedMebersAndAssets;

    InvestorProjectLinked[] public linkedInvestorProject;
    uint public totalLockedTokens;
    AllocatedTokens[] public tokensLockedForProject;
    uint toalPendingRewardTokens;




    // to store member info
    struct Member {
        // the address of member
        address member;
        // date member created  
        uint memberSince;
        // first name of member
        string firstName;
        // last name of member 
        string lastName;
        // email address of member
        string userID;
        // for verification when logging in
        // email address hashed with password    f
        bytes32 memberHash;
        // true if user is admin
        bool admin;
        // if provided referral address is stored
        address referral;
    }


    string[] public asset;

    struct MeberAssetLinked {
        address member;
        uint asset;
        uint cost;
        uint contributed;
    }

    struct InvestorProjectLinked {
        uint projectID;
        address investor;
        uint amount;
        uint percentage;
        uint rewards;
    }

    struct AllocatedTokens {
        address member;
        uint projectID;
        uint tokenAmount;
        uint allocationDate;
        uint tokensAmountDeallocated;
        uint tokensEarned;
        uint tokensToEarn;
        uint memberShare;
    }





    // triggered when new member is created or updated
    event MembershipChanged(address member, string firstName, string lastName, string userID, address memberReferral);
    event AssetsLinked(address member, uint asset, uint amount);

    event BuyTokens(uint numOfTokens, address buyer, uint value);
    event ProjectInvestorLinked(uint projectID, address investor, uint amount);
    event TokensAllocated(uint proposalID, uint numOfTokens, uint share, address investor);
    event ProfitsReturned(uint projectID, address payee, uint amount, address investor);



    /* modifier that allows only shareholders to participate in transactions*/
    modifier onlyShareholders() {
        if (sharesTokenAddress.balanceOf(msg.sender) == 0) throw;
        _;
    }


    function myBit(token tokenAddress) {

        asset.push("roof");
        asset.push("siding");
        asset.push("driveway");
        sharesTokenAddress = tokenAddress;
        singleTokenCost = 1000000000000000;

    }

    /// @dev facilitates linking assetes with the company
    /// @param member - user representing project
    /// @param asset - asset to link.
    /// @return bool - true if executed
    function linkMemberAsset(address member, uint asset, uint cost) returns(bool) {
        uint id = linkedMebersAndAssets.length++;
        linkedMebersAndAssets[id] = MeberAssetLinked({
            member: member,
            asset: asset,
            cost: cost,
            contributed: 0
        });
        numAssetLinks++;
        AssetsLinked(member, asset, cost);
        return true;
    }


    function contributeToProject(uint _projectID, uint _amount, address _investor) returns(bool) {

        MeberAssetLinked m = linkedMebersAndAssets[_projectID];

        m.contributed += _amount;
        uint percentageContributed = ((_amount * 100)/m.cost) ;

        linkedInvestorProject.push(InvestorProjectLinked({
            projectID: _projectID,
            investor: _investor,
            amount: _amount,
            percentage: percentageContributed,
            rewards: 0
        }));
        ProjectInvestorLinked(_projectID, _investor, _amount);
        numPorjectContributions++;
        uint tokensToLock = _amount / singleTokenCost;

        if (!allocateTokens(tokensToLock, percentageContributed, _projectID, _investor)) throw;

        // if (!m.member.send(_amount))
        //    throw;
    }

    function returnRewardsForInvestor(address _investor) constant returns(uint){

        uint rewards;

        for (uint i=0; i< numPorjectContributions; i++){

            if (linkedInvestorProject[i].investor == _investor){
                rewards += linkedInvestorProject[i].rewards;
            }
        }

        return rewards;
    }

    function allocateTokens(uint _tokensToLock, uint percentageContributed, uint _projectId, address _investor) internal returns(bool) {

        if (tokensInCirculation - totalLockedTokens > _tokensToLock) {

            //uint totalAvailableTokens = tokensInCirculation - totalLockedTokens;
            totalLockedTokens += _tokensToLock;

            var (memberAllocatedTokens, memberDeallocatedTokens, ) = returnWorkingTokensForMember(_investor);
            uint memberAvailableTokens = sharesTokenAddress.balanceOf(_investor) - (memberAllocatedTokens - memberDeallocatedTokens);
            // uint memberShare = memberAvailableTokens * 1000000/totalAvailableTokens;
            if (memberAvailableTokens < _tokensToLock) throw;

            AllocatedTokens at = tokensLockedForProject[tokensLockedForProject.length++];
            at.member = _investor;
            at.projectID = _projectId;
            at.tokenAmount = _tokensToLock;

            //at.tokensToEarn = (_tokensToAward * memberShare )/1000000;                   
            at.allocationDate = now;
            at.memberShare = percentageContributed;
            //toalPendingRewardTokens += at.tokensToEarn;

            TokensAllocated(_projectId, _tokensToLock, percentageContributed, _investor);
            return true;
        }

        TokensAllocated(_projectId, 0, 0, _investor);
        return false;
    }

    function returnProfit(uint _projectID, address _payee, uint _amount) returns(bool) {



        for (uint i = 0; i < linkedInvestorProject.length; i++) {

            if (linkedInvestorProject[i].projectID == _projectID) {

                uint amountToSend = (_amount * linkedInvestorProject[i].percentage) / 100;
                linkedInvestorProject[i].rewards += amountToSend;

                sharesTokenAddress.transferFrom(_payee, linkedInvestorProject[i].investor, amountToSend);
                ProfitsReturned(_projectID, _payee, amountToSend, linkedInvestorProject[i].investor);
            }
        }

        return true;
    }

    function returnWorkingTokensForMember(address _member) constant returns(uint, uint, uint, uint) {

        uint totalAllocatedTokensForMember;
        uint totalDeallocatedTokensForMember;
        uint totalRewardsForMember;
        uint totalPendingRewardsForMember;

        for (uint i = 0; i < tokensLockedForProject.length; i++) {

            if (tokensLockedForProject[i].member == _member) {
                totalAllocatedTokensForMember += tokensLockedForProject[i].tokenAmount;
                totalDeallocatedTokensForMember += tokensLockedForProject[i].tokensAmountDeallocated;
                totalRewardsForMember += tokensLockedForProject[i].tokensEarned;
                totalPendingRewardsForMember += tokensLockedForProject[i].tokensToEarn;
            }

        }
        return (totalAllocatedTokensForMember, totalDeallocatedTokensForMember, totalRewardsForMember, totalPendingRewardsForMember);
    }


    /// @dev facilitates buying of tokens
    /// @param numOfTokens - number of tokens to purchased
    /// @return bool - true if executed

    function buyTokens(uint numOfTokens) payable returns(bool) {



        if (msg.sender.balance == 0) throw;

        uint totalTokenCost = singleTokenCost * numOfTokens;
        uint userBalance = msg.sender.balance;
        uint maxTokenToBuy = userBalance / singleTokenCost;

        if (numOfTokens >= maxTokenToBuy || totalTokenCost > msg.value) {
            BuyTokens(0, msg.sender, msg.value);
            throw;
        }

        sharesTokenAddress.mintToken(msg.sender, numOfTokens);
        tokensInCirculation += numOfTokens;


        BuyTokens(numOfTokens, msg.sender, msg.value);

        return true;
    }





    /// @dev to create new member. Function checks if member with this email address exists and if 
    /// it doesn't it creats new member. 
    /// @param targetMember - address of the new member
    /// @param firstName -
    /// @param lastName -
    /// @param userID - email address
    /// @param memberHash - email address and password hash to login
    /// @param tokenNum - number of free tokens to assign if any
    /// @param memberReferral - referral of the member

    function newMember(address targetMember, string firstName, string lastName, string userID, bytes32 memberHash, uint tokenNum, address memberReferral) {


        uint id;
        bool adminFlag = false;



        if (stringsEqualMemory("admin@admin.com", userID)) {
            adminFlag = true;
        }


        if (getMemberByUserID(userID) >= 0) {
            throw;


        } else {

            memberId[targetMember] = members.length;
            id = members.length++;
            members[id] = Member({
                member: targetMember,
                memberSince: now,
                firstName: firstName,
                lastName: lastName,
                userID: userID,
                memberHash: memberHash,
                admin: adminFlag,
                referral: memberReferral
            });
            numMembers++;

            sharesTokenAddress.mintToken(targetMember, tokenNum);
            tokensInCirculation += tokenNum;


        }
        MembershipChanged(targetMember, firstName, lastName, userID, memberReferral);

    }

    /// @dev used to login user into their account. To check if given user exists 
    /// @param userID - user email address
    /// @return int - member position in the array
    function getMemberByUserID(string userID) constant returns(int memberPosition) {

        if (members.length == 0) {
            return -1;
        }

        for (uint i = 0; i < members.length; i++) {
            if (stringsEqual(members[i].userID, userID)) {
                return int(i);
            }

        }
        return -1;

    }


    /// @notice to compare string when one is in memory and other in storage
    /// @param _a Storage string
    /// @param _b Memory string

    function stringsEqual(string storage _a, string memory _b) constant internal returns(bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i++)
            if (a[i] != b[i])
                return false;
        return true;
    }

    /// @notice  to compare strings which both reside in memory
    /// @param _a Memory string
    /// @param _b Memory string 
    function stringsEqualMemory(string memory _a, string memory _b) internal returns(bool) {

        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i++)
            if (a[i] != b[i])
                return false;
        return true;
    }


    /// @dev helper function to concatenate strings

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal constant returns(string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal constant returns(string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns(string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal constant returns(string) {
        return strConcat(_a, _b, "", "", "");
    }



    /// @dev convert uint to string

    function uintToString(uint a) internal constant returns(string) {

        bytes32 st = uintToBytes(a);
        return bytes32ToString(st);
    }

    /// @dev convert uint to Bytes
    function uintToBytes(uint v) internal constant returns(bytes32 ret) {
        if (v == 0) {
            ret = '0';
        } else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    /// @dev convert bytes32 to String 
    function bytes32ToString(bytes32 x) internal constant returns(string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }


}