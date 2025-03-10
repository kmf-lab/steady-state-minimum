use std::error::Error;
use std::time::Duration;
use log::*;
use steady_state::*;

pub async fn run(context: SteadyContext) -> Result<(),Box<dyn Error>> {
    let mut monitor = context.into_monitor([],[]);

    let args = monitor.args::<crate::MainArg>().expect("unable to downcast");
    let rate = Duration::from_millis(args.rate_ms);

    let mut count = args.beats;
    while monitor.is_running(|| true) {
        await_for_all!(monitor.wait_periodic(rate));
        info!("Heartbeat {} {:?}", count, rate );
        count -= 1;
        if  count == 0 {
            monitor.request_graph_stop();
        }
    }
    Ok(())
}
