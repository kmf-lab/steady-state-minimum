# Minimal Steady State Actor Project

A minimal example of actor-based concurrent programming in Rust using the [`steady_state`](https://crates.io/crates/steady_state) framework.

## 🎯 Overview

This project demonstrates the core features of the actor model within a steady-state architecture:

- **Actors**: Independent, message-driven units with isolated state
- **Async Coordination**: Non-blocking timers and cooperative shutdown
- **Safe Concurrency**: No shared memory, race-condition-free
- **Graceful Shutdown**: One actor can trigger a system-wide stop

## 🧠 Key Concepts

### Actors vs Traditional Threading

| Traditional Threading       | Actor Model                         |
|----------------------------|-------------------------------------|
| Shared memory + locks      | Isolated memory + message passing   |
| Race conditions possible   | Race conditions eliminated          |
| Manual synchronization     | Framework-managed coordination      |
| Deadlock-prone             | Deterministic, isolated actors      |

### Steady State Architecture

- **Continuous Loops**: Actors run in a loop until the system signals shutdown
- **Coordinated Termination**: Any actor can call `cmd.request_graph_stop()` to end the system
- **Built-in Monitoring**: Track CPU usage, throughput, and health
- **Backpressure Handling**: Prevents overload by controlling message flow

## 📋 Project Structure

- **Heartbeat Actor**  
  Periodically logs messages and counts down to a system-wide shutdown.

- **Main Graph**  
  Uses the builder pattern to configure and launch the actor system.

### Notable APIs

- `SteadyContext::cmd().into_monitor()` – Enable monitoring
- `cmd.is_running()` – Check system status from within an actor
- `await_for_all!()` – Perform non-blocking periodic operations
- `Threading::Spawn` – Allocate one thread per actor for maximum isolation

## 🚀 Running the App

```bash
cargo run -- --rate 500 --beats 10
