        pragma solidity ^0.4.11;
        
        //Contract token is found in its own file. 
        //These here are interfaces to access functions and variable of token contract.       
        contract token { 
    
                    // balance of tokens for individual member
                    mapping (address => uint256) public balanceOf;  
    
    
                    // this function creates new tokens and assigns it to the purchaser.
                    // It can be only called by the owner of itself or from functions
                    // in this contract which is registered with MyToken contract. 
                                          
                    function mintToken (address target, uint256 mintedAmount);
        }
    
        // @notice a contract which is inherited by 
        // main Association contract. owned holds several housekeeping functions 
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
    
    
        /// @dev Liquid Democracy contract. Allows new members to be registered and 
        /// aquire tokens. Number of acquired tokens also represents user voting power. 
        /// Tokens are held in standard token contract defined here. 
        contract myBit is owned {
    
           
            uint public numMembers;
            // to retrieve a member position in the array without searching for it
            mapping (address => uint) public memberId;   
            
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
            
            struct MeberAssetLinked{
                
                address  member;
                uint asset;
            }
            
            
           
    
      
    
    
            
            // triggered when new member is created or updated
            event MembershipChanged(address member, string firstName, string lastName, string userID, address memberReferral);
            event AssetsLinked(address member, uint asset);
           
            event BuyTokens(uint numOfTokens, address buyer, uint value); 
           
           
            
            /* modifier that allows only shareholders to participate in auction */
            modifier onlyShareholders() {
                if (sharesTokenAddress.balanceOf(msg.sender) == 0) throw;
                    _;
            }
            
            
            function myBit(token tokenAddress){
                
                asset.push("roof");
                asset.push("siding");
                asset.push("driveway");
                sharesTokenAddress = tokenAddress;
                
            }
            
            
            function linkMemberAsset(address member, uint asset) returns (bool) {
                
                
                
                uint id = linkedMebersAndAssets.length++;
                linkedMebersAndAssets[id] = MeberAssetLinked({member: member, asset: asset});
                AssetsLinked(member, asset);
                return true;
            }
    
            
            /// @dev facilitates buying of tokens
            /// @param numOfTokens - number of tokens to purchased
            /// @return bool - true if executed
    
            function buyTokens(uint numOfTokens) payable returns (bool){            
    
              
    
                if (msg.sender.balance == 0) throw;
    
                uint totalTokenCost = singleTokenCost * numOfTokens;
                uint userBalance = msg.sender.balance ;
                uint maxTokenToBuy = userBalance / singleTokenCost;
                
                if ( numOfTokens >= maxTokenToBuy || totalTokenCost > msg.value){               
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
    
            function newMember(address targetMember, string firstName, string lastName, string userID,  bytes32 memberHash, uint tokenNum, address memberReferral)  {
                
                
                uint id;
                bool adminFlag = false;
                
            
                
                if (stringsEqualMemory("admin@admin.com", userID)){adminFlag = true;}
                
    
                if(getMemberByUserID(userID) >= 0){
                    throw;
                    
    
                }
                                    
                else  {
                
                    memberId[targetMember] = members.length ;
                    id = members.length++;
                    members[id] = Member({member: targetMember, memberSince: now, firstName: firstName, lastName:lastName, userID:userID,   memberHash:memberHash, admin:adminFlag, referral:memberReferral});			
                    numMembers++;	
    
                  //  sharesTokenAddress.mintToken(targetMember, tokenNum);
                    tokensInCirculation += tokenNum;            
                    
                    			
                } 
                MembershipChanged(targetMember,  firstName, lastName, userID, memberReferral);
                         
            }
    
            /// @dev used to login user into their account. To check if given user exists 
            /// @param userID - user email address
            /// @return int - member position in the array
            function getMemberByUserID(string userID) constant returns (int memberPosition){
            
                if (members.length == 0) {
                    return -1;
                }
    
                for (uint i=0; i < members.length; i++){
                    if (stringsEqual(members[i].userID , userID) ){
                        return int(i);                
                    }
                    
                }       
            return -1;
            
            }
    
    
            /// @notice to compare string when one is in memory and other in storage
            /// @param _a Storage string
            /// @param _b Memory string
    
            function stringsEqual(string storage _a, string memory _b) constant internal returns (bool) {
    		    bytes storage a = bytes(_a);
    		    bytes memory b = bytes(_b);
    		    if (a.length != b.length)	
    			    return false;
    		    // @todo unroll this loop
    		    for (uint i = 0; i < a.length; i ++)
    			    if (a[i] != b[i])
    				    return false;
    		    return true;
    	    }
    
            /// @notice  to compare strings which both reside in memory
            /// @param _a Memory string
            /// @param _b Memory string 
            function stringsEqualMemory(string memory _a, string memory _b) internal returns (bool) {
        
                bytes memory a = bytes(_a);
                bytes memory b = bytes(_b);
                if (a.length != b.length)	
                    return false;
                    // @todo unroll this loop
                for (uint i = 0; i < a.length; i ++)
                    if (a[i] != b[i])
                        return false;
                    return true;
            }
            
         
            /// @dev helper function to concatenate strings
    
            function strConcat(string _a, string _b, string _c, string _d, string _e) internal constant returns (string){
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
    
            function strConcat(string _a, string _b, string _c, string _d) internal constant returns (string) {
                return strConcat(_a, _b, _c, _d, "");
            }
    
            function strConcat(string _a, string _b, string _c) internal returns (string) {
                return strConcat(_a, _b, _c, "", "");
            }
    
            function strConcat(string _a, string _b) internal constant returns (string) {
                return strConcat(_a, _b, "", "", "");
            }
    
    
        
            /// @dev convert uint to string
    
            function uintToString(uint a) internal constant returns (string){
            
                bytes32 st = uintToBytes(a);
                return bytes32ToString(st);
            }
    
            /// @dev convert uint to Bytes
            function uintToBytes(uint v) internal constant returns (bytes32 ret) {
                if (v == 0) {
                    ret = '0';
                }
                else {
                    while (v > 0) {
                        ret = bytes32(uint(ret) / (2 ** 8));
                        ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                        v /= 10;
                    }
                }
                return ret;
            }
            
            /// @dev convert bytes32 to String 
            function bytes32ToString(bytes32 x) internal constant returns (string) {
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
    
