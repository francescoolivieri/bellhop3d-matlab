function printMap(map)
% Prints the map as table

    T = table(map.keys', map.values', 'VariableNames', {'Key', 'Value'});
    disp(T);
end