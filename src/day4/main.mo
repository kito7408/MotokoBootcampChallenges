import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {
  public type Account = Account.Account;
  let bootcampCanister = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor{
    getAllStudentsPrincipal : shared query () -> async [Principal];
  };

  let ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);

  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the the total number of tokens on all accounts
  public func totalSupply() : async Nat {
    var totalCoins : Nat = 0;
    for ((key, value) in ledger.entries()) {
      totalCoins += value;
    };
    return totalCoins;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    switch (ledger.get(account)) {
      case (null) {
        return 0;
      };
      case (?oneAccount) {
        return oneAccount;
      };
    };
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {
    let senderBalance : Nat = Option.get(ledger.get(from), 0);
    let recipientBalance : Nat = Option.get(ledger.get(to), 0);
    if (senderBalance < amount) {
      return #err("Sender have not enough token to transfer.");
    } else {
      ledger.put(from, senderBalance - amount);
      ledger.put(to, recipientBalance + amount);
      return #ok();
    };
  };

  // Airdrop 100 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
    try {
      let studentsPrincipal = await bootcampCanister.getAllStudentsPrincipal();
      for (p in studentsPrincipal.vals()) {
        let account : Account = {
          owner = p;
          subaccount = null;
        };
        let currentValue = Option.get(ledger.get(account), 0);
        let newValue = currentValue + 100;
        ledger.put(account, newValue);
      };
      return #ok();
    } catch (e) {
      return #err("Something went wrong when calling the bootcamp canister.");
    };

  };
};
