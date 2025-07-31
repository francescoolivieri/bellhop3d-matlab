function data = uncertainty_guided_nbv(data, s, idx)
    % Uncertainty-guided approach inspired by neural rendering methods
    candidate_positions = generate_candidate_positions(data.x(idx), data.y(idx), data.z(idx), s);
    
    best_uncertainty_reduction = -inf;
    best_pos = [data.x(idx), data.y(idx), data.z(idx)];
    
    for i = 1:size(candidate_positions, 1)
        pos = candidate_positions(i, :);
        if is_valid_position(pos, s)
            uncertainty_reduction = calculate_uncertainty_reduction(pos, data.th_est(:, idx), data.Sigma_est(:, :, idx), s);
            if uncertainty_reduction > best_uncertainty_reduction
                best_uncertainty_reduction = uncertainty_reduction;
                best_pos = pos;
            end
        end
    end
    
    data.x(idx+1) = best_pos(1);
    data.y(idx+1) = best_pos(2);
    data.z(idx+1) = best_pos(3);
end

function uncertainty_reduction = calculate_uncertainty_reduction(pos, mu_th, Sigma_thth, s)
    % Calculate uncertainty reduction (similar to information gain but normalized)
    try
        [~, Sigma_new] = step_ukf_filter(nan, @(th)forward_model(th, pos, s), mu_th, Sigma_thth, s.Sigma_rr);
        uncertainty_reduction = (trace(Sigma_thth) - trace(Sigma_new)) / trace(Sigma_thth);
    catch
        uncertainty_reduction = -inf;
    end
end