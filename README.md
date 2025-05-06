# Deadman Switch Canister

This is a demonstration implementation of a deadman switch on the Internet Computer. A deadman switch is a safety mechanism that automatically triggers if a specific action (in this case, a "ping") is not performed within a set time period.

## Concept

The deadman switch canister allows you to:

1. Set a secret message and a timeout period
2. Regularly "ping" the canister to keep it alive
3. If you fail to ping within the timeout period, the secret becomes publicly accessible

This can be useful for scenarios like:

- Ensuring important information is released if you become unavailable
- Creating time-locked secrets that only become available after a period of inactivity
- Demonstrating the concept of automated trustless execution on the Internet Computer

## Interface

The canister provides the following methods:

- `set_secret(secret: text, timeout_value: nat, unit: DurationUnit)`:

  - Sets up the deadman switch with your secret and timeout
  - `unit` can be: `#seconds`, `#minutes`, `#hours`, or `#days`
  - Returns `#ok` or `#err`

- `ping()`:

  - Resets the timer
  - Must be called before the timeout expires
  - Returns `#ok` or `#err`

- `get_state()`:

  - Returns the current state: "ready", "live", or "dead"

- `get_secret()`:
  - Only returns the secret if the switch is in "dead" state
  - Returns `#ok(secret)` or `#err`

## Quick Start

1. Start the local replica:

```bash
dfx start --background
```

2. Deploy the canister:

```bash
dfx deploy
```

3. Try it out with these example commands:

```bash
# Set a secret with a 1-minute timeout
dfx canister call deadman set_secret '("my secret message", 1, #minutes)'

# Check the current state
dfx canister call deadman get_state

# Send a ping to keep it alive
dfx canister call deadman ping

# After the timeout expires, retrieve the secret
dfx canister call deadman get_secret
```

## Notes

- The canister checks for expiration every 5 seconds
- Once the switch is triggered (goes "dead"), it cannot be reset
- The secret is only accessible after the timeout period has expired
- This is a demonstration implementation and should not be used for production secrets without additional security measures
