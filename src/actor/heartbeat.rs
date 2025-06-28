use std::error::Error;
use std::time::Duration;
use log::*;
use steady_state::*;
use std::cell::RefCell;

/// Actor entry point function following the steady_state actor pattern.
/// Every actor must have a `run` function that accepts a SteadyActorShadow and returns
/// a Result. This function serves as the actor's lifecycle manager - if it returns
/// an error (or panics), the steady_state framework will automatically restart the actor,
/// providing fault tolerance without manual error handling.
pub async fn run(actor: SteadyActorShadow) -> Result<(),Box<dyn Error>> {
    // Transform the basic context into a monitoring-enabled SteadyActor.
    // The empty arrays [] represent input and output channel configurations -
    // this actor operates independently without inter-actor communication channels.
    // Monitoring enables this actor to appear in telemetry dashboards with
    // real-time metrics like CPU usage, and throughput.
    // if we passed actor as-is, the code continues to work as expected, but without
    // any telemetry or metrics collection overhead.
    internal_behavior(actor.into_spotlight([], [])).await  //#!#//
}

/// Core actor behavior separated from monitoring concerns for testability.
/// This function accepts any type implementing SteadyActor, allowing the same
/// logic to run with or without monitoring enabled.
async fn internal_behavior<A: SteadyActor>(mut actor: A) -> Result<(),Box<dyn Error>> {
    // Access shared command-line arguments via the type-safe args() method.
    // The steady_state framework automatically provides these arguments to any actor
    // without requiring global variables or parameter threading through function calls.
    let args = actor.args::<crate::MainArg>().expect("unable to downcast");//#!#//
    let rate = Duration::from_millis(args.rate_ms);

    // This RefCell is NOT needed but is here to demonstrate Send trait is not required.
    let count = RefCell::new(args.beats);

    // The fundamental actor event loop: continue while the system is running.
    // The is_running() method checks two conditions:
    // 1. Whether a system-wide shutdown has been requested by any actor
    // 2. Whether this specific actor wants to continue (via the closure parameter)
    // The closure allows actors to implement custom shutdown logic, like completing
    // current work before stopping. Returning false from the closure temporarily
    // vetoes shutdown and allows for one more integration of the loop.
    while actor.is_running(|| true) {  //#!#//
        // The await_for_all! macro is the standard pattern for actor timing control.
        // It waits for ALL listed futures to complete before proceeding, ensuring
        // precise timing coordination. This prevents the common async pitfall of
        // accidentally racing multiple timing conditions. The macro accepts a
        // comma-separated list of futures and yields control back to the runtime
        // once all are ready, enabling efficient cooperative multitasking.
        await_for_all!(actor.wait_periodic(rate));  //#!#//

        // Perform the actor's primary work - in this case, logging a heartbeat.
        // Actor state modifications happen here safely since each actor has
        // complete isolation from other actors. No locks or synchronization needed.
        info!("HEARTBEAT {:?} {:?}", count, rate );
        *count.borrow_mut() -= 1; //unnecessary complexity, but we are showing Send trat not required    //#!#//
        
        // Demonstrate coordinated system shutdown initiated by a single actor.
        // When any actor calls request_shutdown(), the steady_state framework
        // broadcasts a shutdown signal to all actors in the system. This enables
        // clean, coordinated termination without requiring complex inter-actor
        // communication protocols. The await ensures the shutdown request is
        // properly registered before this actor continues to its next loop iteration.
        // if the shutdown barrier count is set on the graph this await will NOT
        // return or trigger the shutdown until the count is reached.
        if  count.borrow().eq(&0) {
            actor.request_shutdown().await;  //#!#//
        }
    }

    // Clean actor termination - returning Ok(()) indicates successful completion.
    // If this actor were to return an Err(), the steady_state framework would
    // automatically restart it, providing built-in resilience.
    Ok(())
}
