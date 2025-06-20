# Reinforcement Learning

This was my attempt at creating some sort of example for reinforcement learning. The goal was to have the "robot" (human) walk forwards without falling. Unfortunately this was unsuccessful but I thought I would still provide
the simulink model and code becuase it is at least somewhere to start. A lot of this is based off the MATLAB example tutorial (), however, I did create a new simulink model (probably why it didn't work! Hopefully this is 
helpful. Here are some suggestions for improvements that I didn't get to:

1. Randomize the initial conditions.
2. Implement muscle torque generators rather then just torque drvien.
3. Use a better physics engine (MuJoCo can interface with simulink https://www.mathworks.com/matlabcentral/fileexchange/128028-simulink-blockset-for-mujoco-simulator)
4. If your computer has a GPU try to take advantage of that (I tried and failed).
