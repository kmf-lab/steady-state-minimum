use std::error::Error;
use std::time::Duration;
use log::*;
use steady_state::*;

// every actor has a run method which takes the context and other needed args
// this method is run to start the actor and run again if the actor should panic
pub async fn run(context: SteadyContext) -> Result<(),Box<dyn Error>> {
    let mut cmd = context.into_monitor([], []);

    let args = cmd.args::<crate::MainArg>().expect("unable to downcast");
    let rate = Duration::from_millis(args.rate_ms);

    let mut count = args.beats;
    // is_running can temporarily veto a shutdown by making this closure return false
    while cmd.is_running(|| true) {
        //This macro awaits on a comma seperated list of futures and returns when all are ready
        await_for_all!(cmd.wait_periodic(rate));
        
        info!("Heartbeat {} {:?}", count, rate );
        count -= 1;
        if  count == 0 {
            //once shutdown has started, this returns so you can exit at top with is_running
            cmd.request_graph_stop().await;
        }
    }
    Ok(())
}
