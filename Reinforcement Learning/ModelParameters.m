%% Constants for the model

%% Time 

Ts = 0.025;
Tf = 10.0;

%% Dimensions

plane_height = 0.2;

foot_length = 0.3;
foot_width = 0.2;
foot_height = 0.05;

shank_length = 0.2;
shank_width = 0.2;
shank_height = 0.5;

thigh_length = 0.2;
thigh_width = 0.2;
thigh_height = 0.5;

torso_length = 0.2;
torso_width = 0.5;
torso_height = 1.0;

init_height = plane_height/2 + foot_height + shank_height + thigh_height + 0.5*torso_height;

%% Contact Parameters

contact_radius = 0.005;
contact_stiffness = 1e5;
contact_damping = 1e3;
mu_k = 0.7;
mu_s = 0.9;
mu_vth = 0.01;

%% World Loss

world_damping = 1e-3;
world_rot_damping = 5e-2;

%% Joint Torque

max_torque = 1000;

%% Standing IC

%Torso velocity
vx0 = 1.0;
vy0 = 0;

%Right angles
right = [90,... %hip
         -90,... %knee
         0]; %ankle
%Left angles
left = [0,... %hip
         0,... %knee
         0]; %ankle
