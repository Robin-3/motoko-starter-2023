import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Time "mo:base/Time";

actor class Homework() {
  type Time = Time.Time;
  type Homework = {
    title : Text;
    description : Text;
    dueDate : Time;
    completed : Bool;
  };

  let homeworkDiary = Buffer.Buffer<Homework>(1);

  // Add a new homework task
  public shared func addHomework(homework : Homework) : async Nat {
    homeworkDiary.add(homework);
    return homeworkDiary.size()-1;
  };

  // Get a specific homework task by id
  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    if(id >= homeworkDiary.size()) {
      return #err("Homework not found");
    } else {
      return #ok(homeworkDiary.get(id));
    };
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    if(id >= homeworkDiary.size()) {
      return #err("Homework not found");
    } else {
      let homeworkUpdated: Homework = {
        title = homework.title;
        description = homework.description;
        dueDate = homework.dueDate;
        completed = homeworkDiary.get(id).completed;
      };
      homeworkDiary.put(id, homeworkUpdated);
      return #ok(());
    };
  };

  // Mark a homework task as completed
  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    if(id >= homeworkDiary.size()) {
      return #err("Homework not found");
    } else {
      let homework = homeworkDiary.get(id);
      let homeworkUpdated: Homework = {
        title = homework.title;
        description = homework.description;
        dueDate = homework.dueDate;
        completed = true;
      };
      homeworkDiary.put(id, homeworkUpdated);
      return #ok(());
    };
  };

  // Delete a homework task by id
  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    if(id >= homeworkDiary.size()) {
      return #err("Homework not found");
    } else {
      let x = homeworkDiary.remove(id);
      return #ok(());
    };
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray<Homework>(homeworkDiary);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    var homework = Buffer.clone<Homework>(homeworkDiary);
    homework.filterEntries(func(_, h) = h.completed == false);
    return Buffer.toArray<Homework>(homework);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    var homework = Buffer.clone<Homework>(homeworkDiary);
    homework.filterEntries(func(_, h) = Text.contains(h.title, #text searchTerm) or Text.contains(h.description, #text searchTerm));
    return Buffer.toArray<Homework>(homework);
  };
};

