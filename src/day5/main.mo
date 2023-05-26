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

import IC "Ic";
import HTTP "Http";
import Type "Types";
import Option "mo:base/Option";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;

  let studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(1, Principal.equal, Principal.hash);
  // stable var studentProfileStoreStable : [(Principal, StudentProfile)] = [];

  // STEP 1 - BEGIN
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    studentProfileStore.put(caller, profile);
    return #ok();
  };

  public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    let resProfile : ?StudentProfile = studentProfileStore.get(p);
    switch (resProfile) {
      case (null) {
        return #err("Principal not found");
      };
      case (?something) {
        return #ok(something);
      };
    };
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    let resProfile : ?StudentProfile = studentProfileStore.get(caller);
    switch (resProfile) {
      case (null) {
        return #err("Principal not found");
      };
      case (?something) {
        studentProfileStore.put(caller, profile);
        return #ok();
      };
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    let resProfile : ?StudentProfile = studentProfileStore.get(caller);
    switch (resProfile) {
      case (null) {
        return #err("Principal not found");
      };
      case (?something) {
        studentProfileStore.delete(caller);
        return #ok();
      };
    };
  };

  // system func preupgrade() {
  //   studentProfileStoreStable := Iter.toArray(studentProfileStore.entries());
  // };

  // system func postupgrade() {
  //   for ((key, profile) in studentProfileStoreStable.vals()) {
  //     studentProfileStore.put(key, profile);
  //   };
  //   studentProfileStoreStable := [];
  // };

  // STEP 1 - END

  // STEP 2 - BEGIN
  type calculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {
    let calculatorCanister : calculatorInterface = actor (Principal.toText(canisterId));
    try {
      let resRes = await calculatorCanister.reset();
      if (resRes != 0) {
        return #err(#UnexpectedValue("Reset function returns an unexpected value."));
      };
      let addRes = await calculatorCanister.add(1);
      if (addRes != 1) {
        return #err(#UnexpectedValue("Add function returns an unexpected value."));
      };
      let subRes = await calculatorCanister.sub(1);
      if (subRes != 0) {
        return #err(#UnexpectedValue("Sub function returns an unexpected value."));
      };
      return #ok();
    } catch (e) {
      return #err(#UnexpectedError("An unexpected error has ocurred: " # Error.message(e)));
    };
  };
  // STEP - 2 END

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally

  func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : [Principal] {
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

  public func verifyOwnership(canisterId : Principal, principalId : Principal) : async Bool {
    let mangCanister : IC.ManagementCanisterInterface = actor ("aaaaa-aa");
    try {
      let canisterStats = await mangCanister.canister_status({
        canister_id = canisterId;
      });
      let controllers = canisterStats.settings.controllers;
      for (p in controllers.vals()) {
        if (p == principalId) {
          return true;
        };
      };
      return false;
    } catch (e) {
      let errMsg = Error.message(e);
      let controllers = parseControllersFromCanisterStatusErrorIfCallerNotController(errMsg);
      for (p in controllers.vals()) {
        if (p == principalId) {
          return true;
        };
      };
      return false;
    };
  };
  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, principalId : Principal) : async Result.Result<(), Text> {
    // let student = studentProfileStore.get(principalId);
    // switch (student) {
    //   case (null) {
    //     return #err("Principal not found.");
    //   };
    //   case (?oneStudent) {
    //     if (await verifyOwnership(canisterId, principalId)) {
    //       let resultBootcamp = await test(canisterId);
    //       switch (resultBootcamp) {
    //         case (#err(_)) {
    //           return #err("There is an error testing the canister.");
    //         };
    //         case (#ok()) {
    //           let graduatedStudent = {
    //             name = oneStudent.name;
    //             team = oneStudent.team;
    //             graduate = true;
    //           };
    //           studentProfileStore.put(principalId, graduatedStudent);
    //           return #ok(true);
    //         };
    //       };
    //     } else {
    //       return #err("The canister doesn't belong to the student.");
    //     };
    //   };
    // };

    let isOwner = await verifyOwnership(canisterId, principalId);
    if (not (isOwner)) {
      return #err("The caller is not the owner of the canister.");
    } else {
      let resultCalcCanister = await test(canisterId);
      switch (resultCalcCanister) {
        case (#err(_)) {
          return #err("The canister does not pass the test.");
        };
        case (#ok()) {
          switch (studentProfileStore.get(principalId)) {
            case (null) {
              return #err("Profile not fount.");
            };
            case (?profile) {
              let newProfile = {
                name = profile.name;
                team = profile.team;
                graduate = true;
              };
              studentProfileStore.put(principalId, newProfile);
              return #ok();
            };
          };
        };
      };
    };
  };
  // STEP 4 - END

  // STEP 5 - BEGIN
  public type HttpRequest = HTTP.HttpRequest;
  public type HttpResponse = HTTP.HttpResponse;

  // NOTE: Not possible to develop locally,
  // as Timer is not running on a local replica
  public func activateGraduation() : async () {
    return ();
  };

  public func deactivateGraduation() : async () {
    return ();
  };

  public query func http_request(request : HttpRequest) : async HttpResponse {
    return ({
      status_code = 200;
      headers = [];
      body = Text.encodeUtf8("");
      streaming_strategy = null;
    });
  };
  // STEP 5 - END
};
