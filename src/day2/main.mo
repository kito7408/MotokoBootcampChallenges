import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";

import Type "Types";

actor class Homework() {
  type Homework = Type.Homework;

  var homeworkDiary = Buffer.Buffer<Homework>(10);

  // Add a new homework task
  public shared func addHomework(homework : Homework) : async Nat {
    homeworkDiary.add(homework);
    return (homeworkDiary.size() - 1);
  };

  // Get a specific homework task by id
  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    if (id < homeworkDiary.size() and id >= 0) {
      return #ok(homeworkDiary.get(id));
    } else {
      return #err("HomeworkID is invalid");
    };
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    if (id < homeworkDiary.size() and id >= 0) {
      homeworkDiary.put(id, homework);
      return #ok();
    } else {
      return #err("HomeworkID is invalid");
    };
  };

  // Mark a homework task as completed
  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    if (id < homeworkDiary.size() and id >= 0) {
      var homeworkSelected = {
        description = homeworkDiary.get(id).description;
        title = homeworkDiary.get(id).title;
        completed = true;
        dueDate = homeworkDiary.get(id).dueDate;
      };
      homeworkDiary.put(id, homeworkSelected);
      return #ok();
    } else {
      return #err("HomeworkID is invalid");
    };
  };

  // Delete a homework task by id
  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    if (id < homeworkDiary.size() and id >= 0) {
      let removedHW = homeworkDiary.remove(id);
      return #ok();
    } else {
      return #err("HomeworkID is invalid");
    };
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray(homeworkDiary);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    let pendingHW = Buffer.clone(homeworkDiary);
    pendingHW.filterEntries(func(_, x) = (x.completed == false));
    return Buffer.toArray(pendingHW);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    let searchedHW = Buffer.clone(homeworkDiary);
    searchedHW.filterEntries(func(_, x) = (Text.contains(x.title, #text searchTerm) or Text.contains(x.description, #text searchTerm)));
    return Buffer.toArray(searchedHW);
  };
};
