# Minimal Steady State Actor Project

A minimal example of actor-based concurrent programming in Rust using the [`steady_state`](https://crates.io/crates/steady_state) framework.

## 🎯 Why This Example is "Minimal"

This lesson focuses on the essential actor patterns:
- Single actor with isolated state
- Basic timing and coordination
- System-wide shutdown coordination

**Coming in later lessons**: Standard projects, Robust durable projects, Performant projects, and Distributed projects.

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

- **Continuous Loops**: Actors run in a loop until the system signals shutdown and await when there is no work.
- **Coordinated Termination**: Any actor can call `actor.request_shutdown().await` to end the system
- **Built-in Monitoring**: Track CPU usage, throughput, channel fill and restart counts
- **Backpressure Handling**: Prevents overload by controlling message flow
- **Fault Tolerance**: Restarts actors on failure (see steady-state-robust for more details)

### Feature Flags

The `steady_state` crate offers a variety of feature flags that customize its functionality, letting you adapt the framework to your application's needs. Below is an explanation of what each feature flag does, focusing on its purpose and behavior rather than how to configure it.

#### Default Features

These features are active by default and form the core of steady_state’s functionality:

- **exec_async_std**  
  Powers asynchronous operations using the async-std runtime. It handles the execution of actors and manages concurrency, providing a lightweight and straightforward async foundation. This ensures both high performance and compatibility with both Linux and Windows.

- **telemetry_server_builtin**  
  Embeds a telemetry server directly into your application’s binary. This allows you to monitor actor performance, message flows, and system health without relying on external servers or an internet connection, making it ideal for offline or self-contained environments.

- **prometheus_metrics**  
  Provides metrics in a format compatible with Prometheus, a popular monitoring tool. You can track system stats like CPU usage, message throughput, and channel fill rates, which can then be visualized in tools like Grafana for detailed analysis.

- **core_display**  
  Offers visibility into which CPU core actors are used at any moment. This helps you understand resource utilization and can assist in debugging or optimizing performance. This value is expected to match the ids your OS task manager assigned to the cores.

- **core_affinity**  
  Enables pinning of actors to specific CPU cores. By controlling which cores handle specific tasks, it reduces context switching and improves cache efficiency, potentially boosting performance.

#### Optional Features

These features are not enabled by default but can be added based on your project’s requirements:

- **telemetry_server_cdn**  
  Delivers telemetry assets (e.g., dashboards and graphs) from a content delivery network (CDN) instead of embedding them in the binary. This shrinks the binary size (about 1MB) but requires an internet connection for telemetry features to work.  
  _Note: Mutually exclusive with telemetry_server_builtin._

- **proactor_nuclei**  
  Switches the async runtime to nuclei, which could use io_uring for high-performance I/O operations. This is designed for applications needing low latency and high throughput, offering a cutting-edge alternative to traditional runtimes.  
  _Note: Cannot be used alongside proactor_tokio or exec_async_std., also not compatible with Windows. (YMMV, under development)

- **proactor_tokio**  
  Integrates both the tokio runtime and io_uring support for async operations. Not recommended, but if you require tokio this is your path.  
  _Note: Incompatible with proactor_nuclei and exec_async_std., also not compatible with Windows. (YMMV, under development)

## 📋 Project Structure

- **Heartbeat Actor**  
  Periodically logs messages and counts down to a system-wide shutdown.

- **Main Graph**  
  Uses the builder pattern to configure and launch the actor system.

### Notable APIs

- `SteadyActor::actor().into_spotlight()` – Enable monitoring
- `actor.is_running()` – Check system status from within an actor
- `await_for_all!()` – Perform non-blocking periodic operations
- `ScheduleAs::SoloAct` – Allocate one thread per actor for maximum isolation

### Observing Your First Actor System

- You must wait about 10 seconds for the rolling stats window to provide the first data
- This window size can be changed by the `with_compute_refresh_window_floor(refresh: Duration, window: Duration)` method on the actor or channel builder
  - Values are adjusted to the nearest power of two, so they may be slightly larger than the requested value
  - `refresh`: this is the rate in which we poll for new data, and the frequency the window is updated as new data is rolled in.
  - `window`: the time duration of the window, the units for average can be estimated by the number of refresh periods found in one window.
- `with_no_refresh_window()` can be used to disable all avg/std/percentile metrics collection.

#### Telemetry

- Telemetry on http://127.0.0.1:9900  (human readable)
- Telemetry on http://127.0.0.1:9900/graph.dot (graph file)

```graph.dot
digraph G {
rankdir=LR;
graph [nodesep=.5, ranksep=2.5];
node [margin=0.1];
node [style=filled, fillcolor=white, fontcolor=black];
edge [color=white, fontcolor=white];
graph [bgcolor=black];
"heartbeat" [label="heartbeat
Window 10.2 secs
Avg mCPU: 0000 
", color=grey, penwidth=3 ];
}
```

#### Prometheus

- Prometheus can scrape on http://127.0.0.1:9900/metrics

```prometheus
avg_mCPU{actor_name="heartbeat"} 0
```

## 🚀 Running the App

```bash
cargo run -- --rate 500 --beats 60
```

### Expected output

```bash
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 4.50s
     Running `target\debug\minimum.exe`
Telemetry on http://127.0.0.1:9900
Prometheus can scrape on http://127.0.0.1:9900/metrics
[2025-05-26 17:34:19.422909 -05:00] T[async-std/runtime] INFO [src\actor\heartbeat.rs:53] Heartbeat 60 1s
[2025-05-26 17:34:20.424119 -05:00] T[async-std/runtime] INFO [src\actor\heartbeat.rs:53] Heartbeat 59 1s
[2025-05-26 17:34:21.421543 -05:00] T[async-std/runtime] INFO [src\actor\heartbeat.rs:53] Heartbeat 58 1s
...
[2025-05-26 17:37:39.175210 -05:00] T[async-std/runtime] INFO [src\actor\heartbeat.rs:53] Heartbeat 2 1s
[2025-05-26 17:37:40.172588 -05:00] T[async-std/runtime] INFO [src\actor\heartbeat.rs:53] Heartbeat 1 1s

Process finished with exit code 0
```

## 🚀 Learning Path

This minimal example establishes the foundation. Here's what's coming:

1. **steady-state-standard**: Typical steady-state project and what you should expect to find
2. **steady-state-robust**: Specialized durable solutions to defend against panics
3. **steady-state-performant**: Specialized high-throughput low-latency solutions
4. **steady-state-distributed**: Spanning applications across pods and nodes (machines)

Each lesson builds on these core concepts while adding real-world complexity.

When reviewing the source code, look for //#!#// which demonstrate key ideas you need to know.

## 📚 Further Reading

- [The Actor Model](https://en.wikipedia.org/wiki/Actor_model)
- [Designing Data-Intensive Applications](https://dataintensive.net/) (see chapters on fault tolerance and recovery)
- [The Reactive Manifesto](https://www.reactivemanifesto.org/)
