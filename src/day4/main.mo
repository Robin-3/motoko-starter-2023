import Buffer "mo:base/Buffer";
import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Error "mo:base/Error";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
// import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {
  public type Account = Account.Account;

  let ledgerAccount = Buffer.Buffer<Account>(1);
  let ledgerBalance = Buffer.Buffer<Nat>(1);

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
    var total = 0;
    for (val in ledgerBalance.vals()) {
      total += val;
    };
    return total;
  };

  func accountIndex(account: Account) : ?Nat {
    Buffer.indexOf<Account>(account, ledgerAccount, Account.accountsEqual)
  };
  
  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    switch(accountIndex(account)) {
      case(?index) {
        return ledgerBalance.get(index);
      };
      case(null) {
        return 0;
      };
    };
  };

  func incrementBalance(account: Account, value: Nat, increment: Bool): async () {
    let balanceValue = await balanceOf(account);
    let balanceIndex = accountIndex(account);
    var newBalance: Nat = balanceValue;
    if(increment) {
      newBalance += value;
    } else {
      newBalance -= value;
    };
    switch(balanceIndex) {
      case(?index) {
        ledgerBalance.put(index, newBalance);
      };
      case(null) {
        ledgerAccount.add(account);
        ledgerBalance.add(newBalance);
      };
    };
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {
    let balanceFrom = await balanceOf(from);
    if(balanceFrom < amount) {
      return #err("Caller has not enough token in it's main account");
    };
    await incrementBalance(from, amount, false);
    await incrementBalance(to, amount, true);
    return #ok(());
  };

  func getAllStudentsAccounts() : async [Account] {
    // let bootcampTestActor = await BootcampLocalActor.BootcampLocalActor();
    // let studentsPrincipal = await bootcampTestActor.getAllStudentsPrincipal();
    let invoiceCanister = actor ("rww3b-zqaaa-aaaam-abioa-cai") : actor {
      getAllStudentsPrincipal : shared () -> async [Principal];
    };
    let studentsPrincipal = await invoiceCanister.getAllStudentsPrincipal();
    let studentsAccount = Buffer.Buffer<Account>(studentsPrincipal.size());
    for (student in studentsPrincipal.vals()) {
        let account = {
          owner = student;
          subaccount = null;
        };
        studentsAccount.add(account);
      };
      return Buffer.toArray<Account>(studentsAccount);
  };

  // Airdrop 100 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
    try {
      let studentsAccounts = await getAllStudentsAccounts();
      for(account in studentsAccounts.vals()) {
        await incrementBalance(account, 100, true);
      };
      return #ok(());
    } catch (e) {
      return #err(Error.message(e));
    };
  };
};

