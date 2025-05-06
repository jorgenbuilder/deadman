import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";

actor DeadmanSwitch {

  // Types
  public type DurationUnit = {
    #seconds;
    #minutes;
    #hours;
    #days;
  };

  // Stable variables for state persistence
  stable var state : Text = "ready";
  stable var secret : Text = "";
  stable var timeout_ns : Nat = 0;
  stable var last_ping : Nat = 0;
  stable var timer_id : ?Timer.TimerId = null;

  // Convert duration to nanoseconds
  private func duration_to_ns(value : Nat, unit : DurationUnit) : Nat {
    switch (unit) {
      case (#seconds) { value * 1_000_000_000 };
      case (#minutes) { value * 60 * 1_000_000_000 };
      case (#hours) { value * 60 * 60 * 1_000_000_000 };
      case (#days) { value * 24 * 60 * 60 * 1_000_000_000 };
    };
  };

  // Convert Int to Nat safely
  private func int_to_nat(i : Int) : Nat {
    if (i < 0) { 0 } else { Int.abs(i) };
  };

  // Timer callback function
  private func check_expiration() : async () {
    if (state != "live") return;

    let current_time = Time.now();
    let time_since_ping = current_time - Int64.toInt(Int64.fromInt(last_ping));
    let time_since_ping_seconds = time_since_ping / 1_000_000_000;
    let time_until_dead = (Int64.toInt(Int64.fromInt(timeout_ns)) - time_since_ping) / 1_000_000_000;

    Debug.print("Tick: " # Int.toText(time_since_ping_seconds) # " seconds since last ping, " # Int.toText(time_until_dead) # " seconds until expiration");

    if (time_since_ping >= Int64.toInt(Int64.fromInt(timeout_ns))) {
      state := "dead";
      switch (timer_id) {
        case (?id) {
          Timer.cancelTimer(id);
          timer_id := null;
        };
        case (null) {
          Debug.print("Timer not running");
        };
      };
      Debug.print("Deadman switch triggered – secret revealed");
      Debug.print("Secret: " # secret);
      Debug.print("Timer stopped.");
    };
  };

  // Public interface
  public func set_secret(new_secret : Text, timeout_value : Nat, unit : DurationUnit) : async Result.Result<(), Text> {
    if (state != "ready") {
      return #err("Can only set secret in ready state");
    };

    secret := new_secret;
    timeout_ns := duration_to_ns(timeout_value, unit);
    last_ping := int_to_nat(Time.now());
    state := "live";

    // Set up repeating timer
    let timer = Timer.recurringTimer(#seconds(5), check_expiration);
    timer_id := ?timer;

    Debug.print("Secret configured with timeout: " # Nat.toText(timeout_value) # " " # debug_show (unit));
    Debug.print("Starting timer");
    #ok(());
  };

  public func ping() : async Result.Result<(), Text> {
    if (state != "live") {
      return #err("Can only ping in live state");
    };

    last_ping := int_to_nat(Time.now());
    Debug.print("Ping received, last_ping updated");
    #ok(());
  };

  public func get_state() : async Text {
    state;
  };

  public func get_secret() : async Result.Result<Text, Text> {
    if (state != "dead") {
      Debug.print("Attempt to retrieve secret before expiration – denied");
      return #err("Secret is not available yet");
    };
    #ok(secret);
  };
};
