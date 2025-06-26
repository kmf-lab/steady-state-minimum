
use steady_state::*;

// Actor modules are organized under actor mod for clarity and maintainability.
// Each actor represents an independent unit of computation with its own state
// and message-driven behavior, following the actor model principles.
pub(crate) mod actor {
    // The heartbeat actor demonstrates the minimal actor pattern
    pub(crate) mod heartbeat;
}

// Static actor name for telemetry, testing and debugging purposes
// I like all caps names, but you are free to use whatever you like.
const NAME_HEARTBEAT: &str = "HEARTBEAT";

/// Command line arguments structure used throughout the actor system.
/// These arguments are shared across all actors via the steady_state framework,
/// allowing consistent configuration without global state or shared memory.
#[derive(Parser, Debug, PartialEq, Clone)]
pub(crate) struct MainArg {
    /// Milliseconds between heartbeat messages - controls actor timing
    #[arg(short = 'r', long = "rate", default_value = "1000")]
    pub(crate) rate_ms: u64,

    /// Number of heartbeats before triggering system shutdown
    #[arg(short = 'b', long = "beats", default_value = "60")]
    pub(crate) beats: u64,
}

fn main() -> Result<(), Box<dyn Error>> {
    let cli_args = MainArg::parse();

    // If the default port 9900 for Telemetry and Prometheus is already in use, 
    // you can override it like this by setting environment variables.
    // unsafe {  // NOTE: Rust requires unsafe block to set environment variables
    //      std::env::set_var("TELEMETRY_SERVER_PORT", "5551");
    //      std::env::set_var("TELEMETRY_SERVER_IP", "127.0.0.1");
    // }    
    
    // Initialize structured logging for the entire actor system.
    // Actors use standard log macros (trace!, debut!, info!, warn!, error!) which are
    // automatically coordinated across all threads without contention.
    init_logging(LogLevel::Info)?;

    // GraphBuilder implements the builder pattern for actor system configuration.
    // The graph represents the entire actor ecosystem - all actors, their
    // relationships, and shared resources like command-line arguments.
    let mut graph = GraphBuilder::default()
                    .build(cli_args);

    // Most projects will build the full graph in a separate function for clarity.  
    // This will be helpful later when we add both more actors and testing.
    build_graph(&mut graph);

    // System startup phase: Initialize all registered actors concurrently.
    // If configured, each actor begins executing in its own thread, starting their event loops.
    // The steady_state framework handles all coordination, panic recovery and lifecycle management.
    graph.start();

    // Main thread blocking phase: Wait for the actor system to complete.
    // The system continues running until one actor calls request_shutdown().await,  
    // which initiates a coordinated shutdown across all actors.
    // The timeout parameter (1 second) defines how long to wait for graceful shutdown
    // before forcefully terminating non-responsive actors.
    // Returns Ok(()) on clean shutdown, or an error listing unresponsive actors.
    graph.block_until_stopped(Duration::from_secs(1))
}

fn build_graph(graph: &mut Graph) {
    // Actor registration phase: Define actors and their execution model.
    // Each actor gets its own isolated execution context with no shared memory.
    graph.actor_builder()
        // Human-readable name for telemetry and debugging purposes. 
        // You could also use .with_name_and_suffix to also include a numeric suffix.
        .with_name(NAME_HEARTBEAT)
        // Enable CPU utilization monitoring in milli-CPU units (1024 = 1 core)
        // This provides real-time performance metrics without significant overhead
        .with_mcpu_avg()
        // Create the actor with its entry point function and threading model
        .build(|context| { actor::heartbeat::run(context) }
               // ScheduleAs::SoloAct allocates a dedicated OS thread per actor,
               // ensuring complete isolation and preventing any shared compute issues.
               // This is the safest threading model for beginners to the actor pattern.
               , SoloAct); // see steady-state-performant for more details
}
