function param_map = paddingSedimentParams(param_map, default_param_map)
% Harmonizes sediment-related parameters to have equal lengths
% If one or more sediment parameters have fewer elements, they are padded
% with their default values.

    sediment_keys = {'density_sediment', 'sound_speed_sediment', 'attenuation_sediment'};
    lengths = zeros(1, numel(sediment_keys));

    % Get current lengths
    for i = 1:numel(sediment_keys)
        key = sediment_keys{i};
        if isKey(param_map, key)
            value = param_map(key);
            if isnumeric(value)
                lengths(i) = length(value);
            else
                error('Parameter "%s" must be numeric.', key);
            end
        else
            warning('Parameter "%s" not found in parameter map.', key);
            lengths(i) = 0;
        end
    end

    max_len = max(lengths);

    % Pad each key to match max_len
    for i = 1:numel(sediment_keys)
        key = sediment_keys{i};
        if isKey(param_map, key)
            val = param_map(key);
            n_missing = max_len - length(val);
            if n_missing > 0
                default_val = default_param_map(key);
                pad = repmat(default_val, 1, n_missing);
                param_map(key) = [val, pad];
            end
        end
    end
end
