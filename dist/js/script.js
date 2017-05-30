"use strict";

var userAccount, canVote, firstName, lastName, userID, actionButton;







var Web3;
var web3;
var message;
var gasAmount;
var gasPrice;
var currAccount;
var supportEmail;
var token;
var myBitHandle;
var exchangeFIAT;
var valueIinFIAT;
var ownedPercentage;
var singleTokenCost = 10000000000000000;
var userBalance;



/**
  * This function is called every time html page is opened.
 * it initiates organization name on the html page and creates
 * web3 objects and establishes connection to the node.
 * it creates handle to the contract based on the contract interface
 * and contract address, which is located in interface.js 
 * it verifies balance of the user and executes appropriate load function
 * based on which html page it calls. 
 *
 * @method init
 * 
*/

function init() {
    currAccount = getCookie("account");


    $("#title-brand").text(organizationName);
    $("#page-title").text(organizationName);
    $("#logo-title-link").html('<a href="http://' + domain + '" class="simple-text">' + organizationName + ' </a>');
    $("#logo-mini-link").html('<a href="http://' + domain + '" class="simple-text">' + organizationName + ' </a>');


    if (getCookie("emailAddress") != "") {
        $("#menu-signup").hide();
        $("#menu-login").hide();
    }




    // Checks Web3 support
    if (typeof web3 !== 'undefined' && typeof Web3 !== 'undefined') {
        // If there's a web3 library loaded, then make your own web3
        web3 = new Web3(web3.currentProvider);
    } else if (typeof Web3 !== 'undefined') {
        // If there isn't then set a provider
        //var Method = require('./web3/methods/personal');
        web3 = new Web3(new Web3.providers.HttpProvider(connectionString));

        if (!web3.isConnected()) {

            $("#alert-danger-span").text(" Problem with connection to the newtwork. Please contact " + supportEmail + " abut it. ");
            $("#alert-danger").show();
            return;
        }
    } else if (typeof web3 == 'undefined' && typeof Web3 == 'undefined') {

        Web3 = require('web3');
        web3 = new Web3();
        web3.setProvider(new web3.providers.HttpProvider(onnectionString));
    }



    var myBitContradct = web3.eth.contract(myBitABI);
    myBitHandle = myBitContradct.at(myBitAddress);

    //gasPrice = web3.eth.gasPrice;
    gasPrice = 20000000000;
    gasAmount = 4000000;

    var etherTokenContract = web3.eth.contract(toeknContractABI);
    token = etherTokenContract.at(tokenContractAddress);

    checkBalance();
}


/**
 * It will show small notification window with passed message
 * 
 * @method showTimeNotification 
 * 
*/

function showTimeNotification(from, align, text) {

    var type = ['', 'info', 'success', 'warning', 'danger', 'rose', 'primary'];

    var color = Math.floor((Math.random() * 6) + 1);

    $.notify({
        icon: "notifications",
        message: text

    }, {
            type: type[color],
            timer: 30000,
            z_index: 10031,
            placement: {
                from: from,
                align: align
            }
        });
}




/**
 * It will return decoded uri based on the url
 * 
 * @method getCookie 
 * @param cname
 * @return cookie value
 * 
*/

function getCookie(cname) {

    var name = cname + "=", ca = document.cookie.split(';'), i, c;

    for (i = 0; i < ca.length; i += 1) {
        c = ca[i];
        while (c.charAt(0) === ' ') {
            c = c.substring(1);
        }
        if (c.indexOf(name) === 0) {
            return c.substring(name.length, c.length);
        }
    }
    return "";
}



/**
 * This function adds fake ether for testing
 * 
 * @method fundAccount 
 * 
*/


function fundAccount() {


    var message = confirm("Are you sure you want to add some Ether for free to your account?")
    if (message) {

        $("#alert-success-span").text("Sending money to you. Should be there shortly... :) Refresh page in a few minutes. ");
        $("#alert-success").show();


        web3.eth.sendTransaction({
            from: adminAccount,
            to: currAccount,
            value: web3.toWei(10000, "ether")
        });

    }


}


/**
 * This function will create new member. 
 * It connects to node.js if in stand alone mode
 * to create encrypted key to be read by geth.
 * store key file is writeen in geth storeky location
 * 
 * @method createNewMember 
 * 
*/


function createNewMember() {

    var target,
        targetElement,
        password,
        firstName,
        lastName,
        userID,
        memberHash,
        emailAddress,
        memberPosition;

    emailAddress = document.getElementById("email-address").value;



    memberPosition = myBitHandle.getMemberByUserID(emailAddress);

    // if (memberPosition.c[0] >= 0 && memberPosition.s == 1) {

    if (memberPosition >= 0) {



        $("#message-status-title").text("");
        message = "This email has been already taken."
        progressActionsAfter(message, false);
        $("#progress").modal();



    }
    else {

        firstName = document.getElementById("first-name").value;
        lastName = document.getElementById("last-name").value;
        password = document.getElementById("inputPassword").value;

        document.cookie = "firstName=" + firstName;
        document.cookie = "lastName=" + lastName;
        document.cookie = "emailAddress=" + emailAddress;
        document.cookie = "delegated=" + "0";
        document.cookie = "admin=" + "0";

        $("#modal-register").modal("hide");
        progressActionsBefore();

        // Case of creating admin account
        if (emailAddress == "admin@admin.com") {
            var account = adminAccount;
            document.cookie = "account=" + account;

            setTimeout(function () {
                memberHash = web3.sha3(emailAddress + password);
                var referral = account;

                try {
                    myBitHandle.newMember(account, true, firstName, lastName, emailAddress, memberHash, defulatTokenAmount, referral, { from: adminAccount, gasPrice: gasPrice, gas: gasAmount });
                }
                catch (err) {
                    displayExecutionError(err);
                    return;
                }

                watchNewMembership();
            }, 3);
        }

        //we need to generate new key for new member. 
        else {



            var xhttp = new XMLHttpRequest();

            xhttp.onreadystatechange = function () {
                if (this.readyState == 4 && this.status == 200) {

                    var account = "0x" + this.responseText;
                    $("#message-status-body").text("Your Ethereum address is: " + account);
                    document.cookie = "account=" + account;

                    web3.eth.sendTransaction({
                        from: adminAccount,
                        to: account,
                        value: web3.toWei(10, "ether")
                    });

                    setTimeout(function () {
                        memberHash = web3.sha3(emailAddress + password);
                        var referral = getCookie("ref");

                        if (referral == "undefined") referral = adminAccount;

                        try {
                            myBitHandle.newMember(account, firstName, lastName, emailAddress, memberHash, defulatTokenAmount, referral, { from: adminAccount, gasPrice: gasPrice, gas: gasAmount });
                        }
                        catch (err) {
                            displayExecutionError(err);
                            return;
                        }

                        watchNewMembership();
                    }, 3);
                }
            };
            var parms = "password=" + password;
            xhttp.open("POST", nodejsUrl, true);
            xhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
            xhttp.send(parms);
        }
    }
}




function checkBalance() {



    //   $.get("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD",
    //      function (data, status) {
    //        if (status == "success") {
    //  var myObj = JSON.parse(data);
    // var length = Object(myObj).length;

    //     exchangeFIAT = data.USD;

    exchangeFIAT = 9.88;

    if (currAccount != "") {


        var account = getCookie("account");

        web3.eth.getBalance(account, function (error, result) {
            if (!error) {

                var accountBalance = result / Math.pow(10, 18);

                userBalance = result;

                valueIinFIAT = exchangeFIAT * accountBalance;

                if (result == 0) {
                    $("#noticeModal").modal();
                    $("#sidebar-menu").hide();
                    $("#your-balance").hide();
                } else {
                    $("#balance-ether").hide();
                    //   $("#alert-success-span").html("You have " + formatNumber(accountBalance)+ "    Eth in your account.<BR>");
                    $("#menu-balance-ether").append((accountBalance * 1).formatMoney(2, '.', ',') + " Eth/" + (valueIinFIAT * 1).formatMoney(2, '.', ',') + " USD");
                    $("#menu-balance-ether").show();
                    $("#your-balance").show();
                    $("#buy-tokens").show();

                }


            }
            else {
                reject(Error(error));
                console.log(error)
            }
        })


        myBitHandle.tokensInCirculation(function (error, totalTokens) {

            token.balanceOf(currAccount, function (error, tokenBalance) {
                if (totalTokens == 0) ownedPercentage = 0
                else
                    ownedPercentage = tokenBalance * 100 / totalTokens;

                var votingPower = 1000;

                if (tokenBalance == 0) {

                    $("#noticeModal").modal();
                    $("#alert-warning").show();
                    $("#sidebar-menu").hide();
                } else {

                    $("#menu-balance-tokens").append("<span title='Amount of tokens you own and your percentage. '>" + formatNumber(tokenBalance) + "/" + Math.round(ownedPercentage * 100) / 100 + "%</span>");
                    $("#menu-balance-tokens").show();
                    $("#your-balance").show();
                }

                $("#user-name").prepend(getCookie("firstName") + " " + getCookie("lastName"));

            })
        })


    }
    else $("#sidebar-menu").hide();

}


/**
 * This function will watch for events from blochchain and report new member created. 
 * 
 * @method watchNewMembership 
 * 
*/

function watchNewMembership() {


    var logAccount, message, refAddress;

    logAccount = myBitHandle.MembershipChanged({ member: userAccount }, { firstName: firstName }, { lastName: lastName }, { userID: userID }, { referralAddress: refAddress });

    // Wait for the events to be loaded
    logAccount.watch(function (error, res) {

        if (res.args.userID == getCookie("emailAddress")) {

            message = '<B><BR>Account successfully created...' + '  <BR><B>First Name:</B>' + res.args.firstName + '<BR><B>Last Name:</B>' + res.args.lastName + '<BR><B>user ID:</B>'
                + res.args.userID + '<BR><B>Can vote:</B>' + res.args.isMember + '<BR><BR>Referral Addres:' + res.args.memberReferral + "<BR>" +
                "We have added " + defulatTokenAmount + " tokens to your account just for signing up. " +
                '<div class="footer text-center">' +
                '<a id="modal-action"  href=" ' + linkAfterSignup + '" class="btn btn-primary btn-round">Continue ..</a>' +
                '</div>';

            progressActionsAfter(message, true);
        } else {
            message = '<B><BR>Account note created due to duplicate user id or other network issues. Try again....';
            progressActionsAfter(message, false);
            clearCookies();
        }
    });

}


/**
 * This function will take user email address and password
 * and hash it, then retrieve hashed user id and password
 * stored on the blockchain and compare. If they are the
 * same, cookies will be written and user considered logged in,
 * 
 * @method userLogin 
 * 
*/

function userLogin() {




    var password,
        userID,
        memberPosition,
        member,
        firstName,
        lastName,
        memberHash,
        addr,
        delegated,
        userIDFromBlockChain,
        isAdmin;

    clearCookies();
    password = document.getElementById("inputPassword-login").value;
    userID = document.getElementById("email-address-login").value;
    memberPosition = myBitHandle.getMemberByUserID(userID) + '';

    if (memberPosition >= 0) {
        member = myBitHandle.members(memberPosition);
        firstName = member[2];
        lastName = member[3];
        memberHash = member[5];
        addr = member[0];
        userIDFromBlockChain = member[4];
        isAdmin = member[6] ? 1 : 0;


        if (memberHash === web3.sha3(userID + password) && userID === userIDFromBlockChain) {
            document.cookie = "firstName=" + firstName;
            document.cookie = "lastName=" + lastName;
            document.cookie = "emailAddress=" + userID;
            document.cookie = "account=" + addr;
            document.cookie = "admin=" + isAdmin;


            $("#alert-success-span").text(" Welcome " + firstName + " " + lastName);
            $("#alert-success").show();

            location.replace('');
        } else {
            showTimeNotification('top', 'right', "Problem with your credentials. Your password user combination might be wrong.")

        }


    } else {
        showTimeNotification('top', 'right', "Problem with your credentials. This members doesn't exist.")
        $("#alert-warning-span").text(" Problem with your credentials. This members doesn't exist.");
    }

    $("#modal-login").modal("hide");
}

/**
 * This function will allow an investor to purchase tokens. 
 * 
 * 
 */

function buyTokens() {

    var numOfTokens, buyer, amountSpent;

    if (!handlePassword("buy-tokens-modal", 2)) return;



    var tokenAmount = $("#token-amount").val();

    var totalTokenCost = singleTokenCost * tokenAmount;

    var maxTokenToBuy = userBalance / singleTokenCost;


    if (totalTokenCost >= userBalance) {

        alert("You don't have enough funds in your account to buy this amount of tokens. You can buy max " + maxTokenToBuy + " of tokens.");
    } else {




        try {
            myBitHandle.buyTokens(tokenAmount, { from: currAccount, gasPrice: gasPrice, gas: gasAmount, value: totalTokenCost }, function (error, result) {
                if (!error)
                    console.log(result)
                else
                    console.error(error);

            });
        }
        catch (err) {
            displayExecutionError(err);
            return;
        }

        progressActionsBefore();

        setTimeout(function () {

            var logEvent = myBitHandle.BuyTokens({ numOfTokens: numOfTokens, buyer: buyer, value: amountSpent });
            logEvent.watch(function (error, res) {

                //  if (tokenAmount == res.args.numOfTokens ) {

                var message = '<B><BR>	You bought ' + res.args.numOfTokens + ' tokens and you have spent ' + res.args.value / Math.pow(10, 18) + " Eth";
                progressActionsAfter(message, true);
                //   }

            });
        }, 3);
    }

}


/**
 * This function will remove current cookies
 * 
 * @method clearCookies 
 * 
*/

function clearCookies() {

    var cookies = document.cookie.split(";");

    for (var i = 0; i < cookies.length; i++) {
        var cookie = cookies[i];
        var eqPos = cookie.indexOf("=");
        var name = eqPos > -1 ? cookie.substr(0, eqPos) : cookie;
        document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 GMT";
    }

}




/**
 * This function will display errors in popup when called
 * 
 * @method displayExecutionError 
 * 
*/
function displayExecutionError(err) {


    showTimeNotification('top', 'right', err)
    setTimeout(function () {
    }, 2000);

}


/**
 * This function will register new asset on the blockchain
 * 
 * @method registerAsset 
 * 
*/

function registerAsset() {

    var asset, member;

    var assetSelected = $("#parm1").val();

    if (!handlePassword("areYouSure", 1)) return;

    progressActionsBefore();

    setTimeout(function () {

        myBitHandle.linkMemberAsset(currAccount, assetSelected, { from: currAccount, gasPrice: gasPrice, gas: gasAmount });

        var logAssetLinked = myBitHandle.AssetsLinked({ member: member, asset: asset });

        logAssetLinked.watch(function (error, res) {

            var solarType;

            if (assetSelected == "0") {

                solarType = "Roof Solar panels";
            } else if (assetSelected == "1") {
                solarType = "Siding Solar Panels";
            }
            else
                solarType = "Driveway Solar Panels";


            message = solarType + "  asset has been linked with member " + currAccount;
            progressActionsAfter(message, true);
        });
    }, 10);


}



/**
 * Function to handle member password
 * 
 * @method handlePassword
 * @param parentWindow 
 * @param mode 
 * 
*/


function handlePassword(parentWindow, mode) {

    var password;

    try {
        if (mode == 0) password = $("#pass").val();
        else if (mode == 2) password = $("#pass-tokens").val();
        else if (mode == 1) password = $("#pass-are-you-sure").val();

        web3.personal.unlockAccount(currAccount, password, 20);
        $("#modal-password").modal("hide");
        $("#" + parentWindow).modal("hide");
        $("#message-status-body").html("");

        return true;

    }
    catch (err) {
        $("#wrong-password-message").show();
        $("#wrong-password-message-integrated").show();
        $("#wrong-password-message-integrated-sure").show();

        return false;
    }
}



/**
 * Function to logut the member
 * 
 * @method  userLogout
 * 
*/

function userLogout() {

    clearCookies();

    $("#alert-success").show();
    $("#dashboard").text("Dashboard");

    showTimeNotification('top', 'right', "You have been successfully logged out.")
    setTimeout(function () {
        location.replace('index.html');
    }, 2000);


}




/**
 * Function to show progress indicator before the blockchain action
 * 
 * @method progressActionsAfter
 * @param message
 * @param success 
 * 
*/


function progressActionsAfter(message, success) {

    if (success) {
        $("#message-status-title").html("Contract executed...<img src='../dist/img/checkmark.gif' height='40' width='43'>");
    }
    else {
        $("#message-status-title").html("Contract executed...<img src='../dist/img/no.png' height='40' width='43'>");
    }

    $("#message-status-body").html("<BR>" + message);

}





/**
 * Function to show progress indicator after the blockchain action
 * 
 * @method progressActionsBefore 
 * 
*/


function displayExecutionError(err) {


    showTimeNotification('top', 'right', err)
    setTimeout(function () {
    }, 2000);

}

function progressActionsBefore() {


    $("#message-status-title").html("");
    $("#message-status-body").html("");
    $("#progress").modal();
    $("#message-status-title").html('Verifying contract... <i class="fa fa-refresh fa-spin" style="font-size:28px;color:red"></i>');
    setTimeout(function () {
        $("#message-status-title").html('Executing contract..<i class="fa fa-spinner fa-spin" style="font-size:28px;color:green"></i>');
    }, 1000);

}



function setFormValidation(id) {
    $(id).validate({
        errorPlacement: function (error, element) {
            $(element).parent('div').addClass('has-error');
        }
    });
}


Number.prototype.formatMoney = function (c, d, t) {
    var n = this,
        c = isNaN(c = Math.abs(c)) ? 2 : c,
        d = d == undefined ? "." : d,
        t = t == undefined ? "," : t,
        s = n < 0 ? "-" : "",
        i = String(parseInt(n = Math.abs(Number(n) || 0).toFixed(c))),
        j = (j = i.length) > 3 ? j % 3 : 0;
    return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
};

function formatNumber(number) {
    number = number.toFixed(0) + '';
    var x = number.split('.');
    var x1 = x[0];
    var x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
        x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
}

$(document).on('submit', '.validateDontSubmit', function (e) {
    //prevent the form from doing a submit
    e.preventDefault();
    return false;
});



// execute creation of new member
$(document).on('submit', '#register-form', '#register-form-initial', function (e) {
    if (e.isDefaultPrevented()) {
        // handle the invalid form...
    } else {
        e.preventDefault();
    }
    createNewMember();
});

// execute creation of new member
$(document).on('submit', '#register-form-initial', function (e) {
    if (e.isDefaultPrevented()) {
        // handle the invalid form...
    } else {
        e.preventDefault();
    }
    createNewMember();
});



// execute login
$(document).on('submit', '#login-form', function (e) {
    if (e.isDefaultPrevented()) {
        userLogin();
        // handle the invalid form...
    } else {
        e.preventDefault();
        userLogin();

    }
});



// trigger function to fund account from alret waring mesage
$(document).on('click', '#fund-account-message', '#fund-account', function (e) {
    fundAccount();
});









$("#register-roof").click(function () {

    actionButton = document.getElementById("modal-action-areyousure");
    actionButton.addEventListener('click', registerAsset);

    $("#sure-mesasge").text("This action will register new asset, are you sure?");
    $("#are-you-sure-title").text("Register Asset")
    $("#modal-action-areyousure").text("Register Asset")
    $("#pass-are-you-sure").val("");
    $("#parm1").val(0);
    $("#areYouSure").modal();

});






$("#register-siding").click(function () {


    actionButton = document.getElementById("modal-action-areyousure");
    actionButton.addEventListener('click', registerAsset);

    $("#sure-mesasge").text("This action will register new asset, are you sure?");
    $("#are-you-sure-title").text("Register Asset")
    $("#modal-action-areyousure").text("Register Asset")
    $("#pass-are-you-sure").val("");
    $("#parm1").val(1);
    $("#areYouSure").modal();

});

$("#register-driveway").click(function () {

    actionButton = document.getElementById("modal-action-areyousure");
    actionButton.addEventListener('click', registerAsset);

    $("#sure-mesasge").text("This action will register new asset, are you sure?");
    $("#are-you-sure-title").text("Register Asset")
    $("#modal-action-areyousure").text("Register Asset")
    $("#pass-are-you-sure").val("");
    $("#parm1").val(2);
    $("#areYouSure").modal();

});










$(document).ready(function () {


    setFormValidation('#login-form');
    setFormValidation('#register-form');
    setFormValidation('#register-form-initial');


    // Remove custom error message from password box when user starts typing again .
    $("#pass").mousedown(function () {
        $("#wrong-password-message").hide();
    });

    // Remove custom error message from password box in the integrated window when user starts typing again .
    $("#pass-are-you-sure").keydown(function () {
        $("#wrong-password-message-integrated").hide();
    });


    // trigger function to add some ether to first time users. 
    $("#fund-account").click(function () {

        fundAccount();

    });



    // Notify users that any of this actions is not implemented yet. 
    $("#transfer-tokens, #sell-tokens, #mine-tokens, #start-new-debate, #current-debates, #live-projects, #funded-projects, #completed-projects").click(function () {
        alert("Feature not impleneted yet. ");

    });



    // hide wrong password message on integrated window when it closes
    $("#areYouSure").on('hidden.bs.modal', function () {
        $("#wrong-password-message-integrated").hide();
    });

    // hide wrong password message on regular password window when it closes
    $("#modal-password").on('hidden.bs.modal', function () {
        $("#wrong-password-message").hide();
    });


    // open login window
    $("#menu-login").click(function () {
        $("#modal-login").modal();
    });

    // open signup window
    $("#menu-signup").click(function () {

        $("#register-form")[0].reset();
        $("#modal-register").modal();
    });


    // trigger logout
    $("#menu-logout").click(function () {

        userLogout();
    });


    //handel opening of buy token window
    $("#buy-tokens, #buy-tokens-message").click(function () {

        actionButton = document.getElementById("modal-action-buy-tokens");
        actionButton.addEventListener('click', buyTokens);
        $("#pass-tokens").val("");
        $("#buy-tokens-modal").modal();
    });


});









