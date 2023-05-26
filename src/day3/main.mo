import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Order "mo:base/Order"

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  stable var messageId : Nat = 0;
  let wall = HashMap.HashMap<Nat, Message>(1, Nat.equal, Hash.hash);

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let newMessage = {
      content = c;
      vote = 0;
      creator = caller;
    };
    let id : Nat = messageId;
    messageId += 1;
    wall.put(id, newMessage);
    return id;
  };

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    let resMessage : ?Message = wall.get(messageId);
    switch (resMessage) {
      case (null) {
        return #err("ID is invalid");
      };
      case (?currentMessage) {
        return #ok(currentMessage);
      };
    };
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    let resMessage : ?Message = wall.get(messageId);
    switch (resMessage) {
      case (null) {
        return #err("ID is invalid");
      };
      case (?currentMessage) {
        if (currentMessage.creator == caller) {
          let updatedMessage : Message = {
            content = c;
            vote = currentMessage.vote;
            creator = currentMessage.creator;
          };
          wall.put(messageId, updatedMessage);
          return #ok();
        } else {
          return #err("You are not the creator of the post");
        };
      };
    };
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    let resMessage : ?Message = wall.get(messageId);
    switch (resMessage) {
      case (null) {
        return #err("ID is invalid");
      };
      case (?currentMessage) {
        ignore wall.remove(messageId);
        return #ok();
      };
    };
  };

  // Voting
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    let resMessage : ?Message = wall.get(messageId);
    switch (resMessage) {
      case (null) {
        return #err("ID is invalid");
      };
      case (?currentMessage) {
        let updatedMessage : Message = {
          content = currentMessage.content;
          vote = currentMessage.vote + 1;
          creator = currentMessage.creator;
        };
        wall.put(messageId, updatedMessage);
        return #ok();
      };
    };
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    let resMessage : ?Message = wall.get(messageId);
    switch (resMessage) {
      case (null) {
        return #err("ID is invalid");
      };
      case (?currentMessage) {
        let updatedMessage : Message = {
          content = currentMessage.content;
          vote = currentMessage.vote - 1;
          creator = currentMessage.creator;
        };
        wall.put(messageId, updatedMessage);
        return #ok();
      };
    };
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    let messageBuffer = Buffer.Buffer<Message>(1);
    for ((key, value) in wall.entries()) {
      messageBuffer.add(value);
    };
    return Buffer.toArray(messageBuffer);
  };

  private func _compareMessages(m1 : Message, m2: Message) : Order.Order{
    if(m1.vote == m2.vote) {
      return #equal;
    };
    if(m1.vote < m2.vote){
      return #greater;
    };
    return #less;
  };

  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {
    let messageBuffer = Buffer.Buffer<Message>(1);
    for ((key, value) in wall.entries()) {
      messageBuffer.add(value);
    };
    messageBuffer.sort(_compareMessages);
    return Buffer.toArray(messageBuffer);
  };
};
