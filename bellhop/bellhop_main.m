clc
addpath(genpath('code'))
close all;

% Get settings
s=get_settings();

% Draw true parameters from prior
data=draw_true_theta(s); 

% Initialize filter 
data=init_filter(data,s);

for n=2:s.N+1
        
    % Print state
    fprintf('Iteration nr %d \n',n)

    

    % Update estimate
    data=ukf(data,s);

    % Display result
    plot_result(data,s);
  
end







