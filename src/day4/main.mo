import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
// import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {
  public type Account = Account.Account;

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
    var total = 0;
    for (val in ledger.vals()) {
      total += val;
    };
    return total;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    switch(ledger.get(account)) {
      case(?a) {
        return a;
      };
      case(null) {
        return 0;
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
      return #err("Caller has not enough token in it's main account.");
    };
    let balanceTo = await balanceOf(to);
    ledger.put(from, balanceFrom-amount);
    ledger.put(to, balanceFrom+amount);
    return #ok(());
  };

  // Airdrop 100 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
    // let bootcampTestActor = await BootcampLocalActor.BootcampLocalActor();
    // let students = await bootcampTestActor.getAllStudentsPrincipal();
    let invoiceCanister = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor {
      getAllStudentsPrincipal : shared() -> async [Principal];
    };
    let students = await invoiceCanister.getAllStudentsPrincipal();
    for (student in students.vals()) {
      let account = {
        owner = student;
        subaccount = null;
      };
      ledger.put(account, 100);
    };
    return #ok(());
  };
};

