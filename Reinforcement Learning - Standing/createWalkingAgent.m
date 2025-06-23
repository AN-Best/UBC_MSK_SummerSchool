ModelParameters;

%% Actions and Observations

nObs = 28;
nAct = 6;

obsInfo = rlNumericSpec([nObs 1]);
actInfo = rlNumericSpec([nAct 1]);
actInfo.LowerLimit = -1;
actInfo.UpperLimit = 1;

%% Environment

mdl = 'RLModel';
blk = mdl + "/RL Agent";
env = rlSimulinkEnv(mdl,blk,obsInfo,actInfo);


%% Create Networks - Critic

% Define observation path.
obsPath = [
    sequenceInputLayer(prod(obsInfo.Dimension),Name="obsInLyr")
    fullyConnectedLayer(400)
    reluLayer
    fullyConnectedLayer(300,Name="obsOutLyr")
    ];

% Define action path.
actPath = [
    sequenceInputLayer(prod(actInfo.Dimension),Name="actInLyr")
    fullyConnectedLayer(300,Name="actOutLyr")
    ];

% Define common path.
commonPath = [
    concatenationLayer(1,2,Name="cat")
    reluLayer
    lstmLayer(16);
    fullyConnectedLayer(1)
    ];

% Create dlnetwork object and add layers.
criticNet = dlnetwork;
criticNet = addLayers(criticNet,obsPath);
criticNet = addLayers(criticNet,actPath);
criticNet = addLayers(criticNet,commonPath);

% Connect paths.
criticNet = connectLayers(criticNet,"obsOutLyr","cat/in1");
criticNet = connectLayers(criticNet,"actOutLyr","cat/in2");

criticNet1 = initialize(criticNet);
criticNet2 = initialize(criticNet);

critic1 = rlQValueFunction(criticNet1,obsInfo,actInfo);
critic2 = rlQValueFunction(criticNet2,obsInfo,actInfo);

%% Create Networks - Actor

actorNet = [
    sequenceInputLayer(prod(obsInfo.Dimension))
    fullyConnectedLayer(400)
    lstmLayer(8)
    reluLayer
    fullyConnectedLayer(300)
    reluLayer
    fullyConnectedLayer(prod(actInfo.Dimension))                       
    tanhLayer
    ];

actorNet = dlnetwork(actorNet);
actorNet = initialize(actorNet);
summary(actorNet)

actor  = rlContinuousDeterministicActor(actorNet,obsInfo,actInfo);

%% Actor & Critic Options

criticOptions = rlOptimizerOptions( ...
    Optimizer="adam", ...
    LearnRate=1e-3,... 
    GradientThreshold=1, ...
    L2RegularizationFactor=2e-4);

actorOptions = rlOptimizerOptions( ...
    Optimizer="adam", ...
    LearnRate=1e-3,...
    GradientThreshold=1, ...
    L2RegularizationFactor=1e-5);


%% Create Agent

agentOptions = rlTD3AgentOptions;
agentOptions.DiscountFactor = 0.99;
agentOptions.SequenceLength = 32;
agentOptions.TargetSmoothFactor = 5e-3;
agentOptions.TargetPolicySmoothModel.Variance = 0.2;
agentOptions.TargetPolicySmoothModel.LowerLimit = -0.5;
agentOptions.TargetPolicySmoothModel.UpperLimit = 0.5;
agentOptions.CriticOptimizerOptions = criticOptions;
agentOptions.ActorOptimizerOptions = actorOptions;
agentOptions.SampleTime = Ts;

agent = rlTD3Agent(actor,[critic1,critic2],agentOptions);

%% Train Agent

% training options
trainOpts = rlTrainingOptions(...
    MaxEpisodes=3000, ...
    MaxStepsPerEpisode=floor(Tf/Ts), ...
    ScoreAveragingWindowLength=50, ...
    StopTrainingCriteria="AverageSteps", ...
    StopTrainingValue=floor(Tf/Ts), ...
    SimulationStorageType="none",...
    Verbose=1);

trainOpts.UseParallel = 1;
trainOpts.ParallelizationOptions.Mode = "async";


trainResult = train(agent,env,trainOpts);

