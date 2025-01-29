use steady_state::*;
use structopt::*;
use structopt_derive::*;
pub(crate) mod actor {
   pub(crate) mod heartbeat;
}

#[derive(StructOpt, Debug, PartialEq, Clone)]
pub(crate) struct MainArg {
    #[structopt(short = "r", long = "rate", default_value = "1000")]
    pub(crate) rate_ms: u64,
    #[structopt(short = "b", long = "beats", default_value = "60")]
    pub(crate) beats: u64,
}

fn main() {
    let cli_args = MainArg::from_args();
    let _ = init_logging("info");
    let mut graph = GraphBuilder::default()
           .build(cli_args); //or pass () if no args

    //add one actor to the graph
    graph.actor_builder()
         .with_name("heartbeat")
         .with_mcpu_avg()
         .build(|context| { actor::heartbeat::run(context) }
               , &mut Threading::Spawn);
    //startup entire graph
    graph.start();
    // your graph is running here until actor calls graph stop
    graph.block_until_stopped(std::time::Duration::from_secs(1));
}
