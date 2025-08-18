function info_gain = calculate_information_gain(sim, pos, mu_th, Sigma_thth, Sigma_rr)
    % Calculate information gain using entropy reduction
    try
        fprintf("Position %f %f %f\n", pos);

        fwd_model = @(theta) fwd_with_params(sim, sim.params.getEstimationParameterNames, theta, pos);
        
        [~, Sigma_new] = step_ukf_filter(nan, fwd_model, mu_th, Sigma_thth, Sigma_rr);
        info_gain = sum(diag(Sigma_thth)) - sum(diag(Sigma_new));
        fprintf("Information Gain for %f %f %f is: %f \n", pos, info_gain);
        
    catch ME
        disp('Error in calculate_information_gain:');
        disp(getReport(ME));  % This gives full stack trace and message
        info_gain = -inf;
    end
end