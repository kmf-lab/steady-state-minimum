use steady_state::*;
use clap::*;

// each of the actors is found under this folder
pub(crate) mod actor {
    // for clarity every actor is its own module
   pub(crate) mod heartbeat;
}

#[derive(Parser, Debug, PartialEq, Clone)]
pub(crate) struct MainArg {
    #[arg(short = 'r', long = "rate", default_value = "1000")]
    pub(crate) rate_ms: u64,
    #[arg(short = 'b', long = "beats", default_value = "60")]
    pub(crate) beats: u64,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli_args = MainArg::parse();
    let _ = init_logging(LogLevel::Info);
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
    
    // your graph is running here until the actor calls graph stop
    // returns Ok(()) upon clean shutdown otherwise reports list of actors refusing to shut down
    graph.block_until_stopped(std::time::Duration::from_secs(1))
}
