import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

import Ic "Ic";
// import HTTP "Http";
import Type "Types";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;

  let studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(500, Principal.equal, Principal.hash);

  // STEP 1 - BEGIN
  public shared({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    try {
      studentProfileStore.put(caller, profile);
      return #ok;
    } catch (e) {
      return #err(Error.message(e));
    };
  };

  public shared({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    let studentProfile = studentProfileStore.get(p);
    switch (studentProfile) {
      case (?profile) {
        return #ok(profile);
      };
      case (null) {
        return #err("Student profile not found");
      };
    };
  };

  public shared({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    let studentProfile = studentProfileStore.get(caller);
    switch (studentProfile) {
      case (?profile) {
        studentProfileStore.put(caller, profile);
        return #ok;
      };
      case (null) {
        return #err("Student profile not found");
      };
    };
  };

  public shared({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    let studentProfile = studentProfileStore.get(caller);
    switch (studentProfile) {
      case (?profile) {
        studentProfileStore.delete(caller);
        return #ok;
      };
      case (null) {
        return #err("Student profile not found");
      };
    };
  };
  // STEP 1 - END

  // STEP 2 - BEGIN
  type calculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {
    let calculator = actor(Principal.toText(canisterId)) : calculatorInterface;
    try {
      var clear = await calculator.reset();
      let x1 = await calculator.add(8);
      if (x1 != 8) {
        return #err(#UnexpectedValue("Error 'add'"));
      };
      clear := await calculator.reset();
      let x2 = await calculator.sub(5);
      if (x2 != -5) {
        return #err(#UnexpectedValue("Error 'sub'"));
      };
      let x3 = await calculator.reset();
      if (x3 != 0) {
        return #err(#UnexpectedValue("Error 'reset'"));
      };
      return #ok();
    } catch (e) {
      return #err(#UnexpectedError("Error calculator"));
    };
  };
  // STEP - 2 END

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  let IcId = "aaaaa-aa";
  let ic = actor (IcId) : Ic.ManagementCanisterInterface;

  private func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : async [Principal] {
    let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
    let words = Iter.toArray(Text.split(lines[1], #text(" ")));
    var i = 2;
    let controllers = Buffer.Buffer<Principal>(0);
    while (i < words.size()) {
      controllers.add(Principal.fromText(words[i]));
      i += 1;
    };
    Buffer.toArray<Principal>(controllers);
  };

  public shared func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
    var controllers : [Principal] = [];
    try {
      let canisterStatus = await ic.canister_status({ canister_id = canisterId });
      controllers := canisterStatus.settings.controllers;
    } catch (err) {
      controllers := await parseControllersFromCanisterStatusErrorIfCallerNotController(
        Error.message(err)
      );
    };

    for (controller in controllers.vals()) {
      if (Principal.equal(controller, p)) return true;
    };
    return false;
  };
  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    let ownership = await verifyOwnership(canisterId, p);
    let res = await test(canisterId);
    if (ownership and Result.isOk(res)) {
      switch (studentProfileStore.get(caller)) {
        case null return #err("student not found");
        case (?student) {
          let s = { name = student.name; team = student.team; graduate = true };
          studentProfileStore.put(p, s);
          return #ok();
        };
      };
    };
    return #err("failed verification");
  };
  // STEP 4 - END

  // STEP 5 - BEGIN
  // public type HttpRequest = HTTP.HttpRequest;
  // public type HttpResponse = HTTP.HttpResponse;

  // NOTE: Not possible to develop locally,
  // as Timer is not running on a local replica
  // public func activateGraduation() : async () {
  //   return ();
  // };

  // public func deactivateGraduation() : async () {
  //   return ();
  // };

  // public query func http_request(request : HttpRequest) : async HttpResponse {
  //   return ({
  //     status_code = 200;
  //     headers = [];
  //     body = Text.encodeUtf8("");
  //     streaming_strategy = null;
  //   });
  // };
  // STEP 5 - END
};
