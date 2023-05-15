import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  // Función de hash alternativa para claves de tipo Nat
  func hashNat(n: Nat): Hash.Hash {
    let text = Nat.toText(n);
    return Text.hash(text);
  };

  var mId = 0;
  let wall = HashMap.HashMap<Nat, Message>(5, Nat.equal, hashNat);

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(content : Content) : async Nat {
    let message = {
      content;
      vote = 0;
      creator = caller;
    };
    wall.put(mId, message);
    mId += 1;
    return mId - 1;
  };

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    switch(wall.get(messageId)) {
      case(?message) {
        return #ok(message);
      };
      case(_) { // case(null)
        return #err("Message not found");
      };
    };
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, content : Content) : async Result.Result<(), Text> {
    switch (wall.get(messageId)) {
      case (?message) {
        let creator = message.creator;
        if(creator != caller) {
          return #err("Message not created");
        };
        let newMessage = {
          content;
          vote = message.vote;
          creator;
        };
        wall.put(messageId, newMessage);
        return #ok(());
      };
      case(_) { // case(null)
        return #err("Message not found");
      };
    }
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)) {
      case(?message) {
        wall.delete(messageId);
        return #ok(());
      };
      case(_) { // case(null)
        return #err("Message not found");
      };
    };
  };

  // Voting
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)) {
      case(?message) {
        let newMessage = {
          content = message.content;
          vote = message.vote+1;
          creator = message.creator;
        };
        wall.put(messageId, newMessage);
        return #ok(());
      };
      case(_) { // case(null)
        return #err("Message not found");
      };
    };
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)) {
      case(?message) {
        let newMessage = {
          content = message.content;
          vote = message.vote-1;
          creator = message.creator;
        };
        wall.put(messageId, newMessage);
        return #ok(());
      };
      case(_) { // case(null)
        return #err("Message not found");
      };
    };
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    let messages = Buffer.Buffer<Message>(wall.size());
    for (message in wall.vals()) {
      messages.add(message);
    };
    return Buffer.toArray<Message>(messages);
  };

  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {
    let messages = Buffer.Buffer<Message>(wall.size());
    for (message in wall.vals()) {
      var i = 0;
      while (i < messages.size() and message.vote <= messages.get(i).vote) {
        i += 1;
      };
      messages.insert(i, message);
    };
    return Buffer.toArray<Message>(messages);
  };
};

