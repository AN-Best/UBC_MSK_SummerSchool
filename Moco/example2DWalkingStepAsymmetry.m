% ---------------------------------------------------------------------------- %
% OpenSim Moco: example2DWalkingStepAsymmetry.m                                %
% ---------------------------------------------------------------------------- %
% Copyright (c) 2021 Stanford University and the Authors                       %
%                                                                              %
% Author(s): Russell T. Johnson                                                %
%            University of Southern California, rtjohnso@usc.edu               % 
%                                                                              %
% Licensed under the Apache License, Version 2.0 (the "License"); you may      %
% not use this file except in compliance with the License. You may obtain a    %
% copy of the License at http://www.apache.org/licenses/LICENSE-2.0            %
%                                                                              %
% Unless required by applicable law or agreed to in writing, software          %
% distributed under the License is distributed on an "AS IS" BASIS,            %
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.     %
% See the License for the specific language governing permissions and          %
% limitations under the License.                                               %
% ---------------------------------------------------------------------------- %

% Simulate asymmetric gait using MocoStepTimeAsymmetryGoal and 
% MocoStepLengthAsymmetryGoal. This is an extension of the example2DWalking 
% MATLAB example (see example2DWalking.m for details about the model and data 
% used).
function example2DWalkingStepAsymmetry()

% Simulate asymmetric step times using MocoStepTimeAsymmetryGoal.
stepTimeAsymmetry();

% Simulate asymmetric step lengths using MocoStepLengthAsymmetryGoal.
stepLengthAsymmetry();

end

% Step Time Asymmetry
% -------------------
% Set up a predictive optimization problem where the goal is to minimize an 
% effort cost (cubed controls) and hit a target step time asymmetry. Unlike 
% example2DWalking, this problem requires simulating a full gait cycle. 
% Additionally, endpoint constraints enforce periodicity of the coordinate values 
% (except for pelvis tx) and speeds, coordinate actuator controls, and muscle 
% activations.
%
% Step time is defined as the time between consecutive foot strikes. Step Time 
% Asymmetry (STA) is a ratio and is calculated as follows:
%  - Right Step Time (RST) = Time from left foot-strike to right foot-strike
%  - Left Step Time (LST)  = Time from right foot-strike to left foot-strike
%  - STA = (RST - LST) / (RST + LST)
%
% The step time goal works by "counting" the number of nodes that each foot is in 
% contact with the ground (with respect to a specified contact force threshold). 
% Since, in walking, there are double support phases where both feet are on the 
% ground, the goal also detects which foot is in front and assigns the step time 
% to the leading foot. Altogether, it estimates the time between consecutive 
% heel strikes in order to infer the left and right step times.
%
% The contact elements for each foot must specified via 'setLeftContactGroup()'
% and 'setRightContactGroup()'. The force element and force threshold used to 
% determine when a foot is in contact is set via 'setContactForceDirection()' and 
% 'setContactForceThreshold()'.
%
% Users must provide the target asymmetry value via 'setTargetAsymmetry()'.
% Asymmetry values ranges from -1.0 to 1.0. For example, 0.20 is 20% positive
% step time asymmetry with greater right step times than left step times. A
% symmetric step times solution can be achieved by setting this property to zero.
% This goal can be used only in 'cost' mode, where the error between the target
% asymmetry and model asymmetry is squared. To make this goal suitable for
% gradient-based optimization, step time values are assigned via smoothing
% functions which can be controlled via 'setAsymmetrySmoothing()' and
% 'setContactDetectionSmoothing()'.
%
% Since this goal doesn't directly compute the step time asymmetry from heel 
% strikes, users should confirm that the step time asymmetry from the solution 
% matches closely to the target. To do this, we provide the helper function 
% computeStepAsymmetryValues() below.
function stepTimeAsymmetry()

import org.opensim.modeling.*;

% Create a MocoStudy
% ------------------
study = MocoStudy();
study.setName('example2DWalking_StepTimeAsymmetry');

% Define the MocoProblem
% ----------------------
problem = study.updProblem();
modelProcessor = ModelProcessor('2D_gait.osim');                   
modelProcessor.append(ModOpTendonComplianceDynamicsModeDGF('implicit')); 
problem.setModelProcessor(modelProcessor);  
problem.setTimeBounds(0, 0.94);

% Goals
% =====

% Periodicity 
% -----------
periodicityGoal = MocoPeriodicityGoal('periodicity');
model = modelProcessor.process();
model.initSystem();
% All states are periodic except for the value of the pelvis_tx coordinate.
for i = 1:model.getNumStateVariables()
   currentStateName = string(model.getStateVariableNames().getitem(i-1));
  if ~contains(currentStateName,'pelvis_tx/value')
     periodicityGoal.addStatePair(MocoPeriodicityGoalPair(currentStateName));
  end
end
% The lumbar actuator control is periodic.
periodicityGoal.addControlPair(MocoPeriodicityGoalPair('/lumbarAct'));
problem.addGoal(periodicityGoal);

% Average gait speed
% ------------------
speedGoal = MocoAverageSpeedGoal('speed');
speedGoal.set_desired_average_speed(1.0);
problem.addGoal(speedGoal);

% Effort over distance
% --------------------
effortGoal = MocoControlGoal('effort', 10.0);
effortGoal.setExponent(3);
effortGoal.setDivideByDisplacement(true);
problem.addGoal(effortGoal);

% Step time asymmetry
% -------------------
% The settings here have been modified from the default values to suit this 
% specific problem.
stepTimeAsymmetry = MocoStepTimeAsymmetryGoal();
% Value for smoothing term used to compute when foot contact is made (default is 
% 0.25). Users may need to adjust this based on convergence and matching the 
% target asymmetry.
stepTimeAsymmetry.setContactDetectionSmoothing(0.4);
% (N) contact threshold based on vertical GRF; default value = 25
stepTimeAsymmetry.setContactForceThreshold(25);
% Value for smoothing term use to compute asymmetry (default is 10). Users may 
% need to adjust this based on convergence and matching the target
% asymmetry.
stepTimeAsymmetry.setAsymmetrySmoothing(3);
% Target step length asymmetry: positive numbers mean greater right step lengths 
% than left.
stepTimeAsymmetry.setTargetAsymmetry(0.10);   
% Set goal weight.
stepTimeAsymmetry.setWeight(5);          

% Need to define the names of the left and right heel spheres: this is
% used to detect which foot is in front during double support phase.
forceNamesRightFoot = StdVectorString();
forceNamesRightFoot.add('contactHeel_r');
forceNamesRightFoot.add('contactFront_r');
forceNamesLeftFoot = StdVectorString();
forceNamesLeftFoot.add('contactHeel_l');
forceNamesLeftFoot.add('contactFront_l');
stepTimeAsymmetry.setRightContactGroup(forceNamesRightFoot, 'contactHeel_r');
stepTimeAsymmetry.setLeftContactGroup(forceNamesLeftFoot, 'contactHeel_l');

% Add the goal to the problem. 
problem.addGoal(stepTimeAsymmetry);              

% Bounds
% ======
problem.setStateInfo('/jointset/groundPelvis/pelvis_tilt/value', [-20*pi/180, 20*pi/180]);
problem.setStateInfo('/jointset/groundPelvis/pelvis_tx/value',[0, 2], 0);
problem.setStateInfo('/jointset/groundPelvis/pelvis_ty/value', [0.75, 1.25]);
problem.setStateInfo('/jointset/hip_l/hip_flexion_l/value', [-10*pi/180, 60*pi/180]);
problem.setStateInfo('/jointset/hip_r/hip_flexion_r/value', [-10*pi/180, 60*pi/180]);
problem.setStateInfo('/jointset/knee_l/knee_angle_l/value', [-50*pi/180, 0]);
problem.setStateInfo('/jointset/knee_r/knee_angle_r/value', [-50*pi/180, 0]);
problem.setStateInfo('/jointset/ankle_l/ankle_angle_l/value', [-15*pi/180, 25*pi/180]);
problem.setStateInfo('/jointset/ankle_r/ankle_angle_r/value', [-15*pi/180, 25*pi/180]);
problem.setStateInfo('/jointset/lumbar/lumbar/value', [0, 20*pi/180]);

% Configure the solver
% ====================
solver = study.initCasADiSolver();
solver.set_num_mesh_intervals(100);
solver.set_verbosity(2);
solver.set_optim_convergence_tolerance(1e-4);
solver.set_optim_constraint_tolerance(1e-4);
solver.set_optim_max_iterations(2000);

% Use the tracking problem solution from example2DWalking as the initial
% guess, if it exists. If it doesn't exist, users can run example2DWalking.m to 
% generate this file.
if exist('example2DWalking_StepTimeAsymmetry_solution.sto', 'file')
    solver.setGuessFile('example2DWalking_StepTimeAsymmetry_solution.sto');
end

% Now that we've finished setting up the MocoStudy, print it to a file.
study.print('example2DWalking_StepTimeAsymmetry.omoco');

% Solve the problem
% =================
solution = study.solve();

% Write the solution to a file.
solution.write('example2DWalking_StepTimeAsymmetry_solution.sto');

% Write solution's GRF to a file.
externalForcesTableFlat = opensimMoco.createExternalLoadsTableForGait(model, ...
    solution, forceNamesRightFoot, forceNamesLeftFoot);
STOFileAdapter.write(externalForcesTableFlat, ...
                     'example2DWalking_StepTimeAsymmetry_grfs.sto');
                
study.visualize(solution);

end

