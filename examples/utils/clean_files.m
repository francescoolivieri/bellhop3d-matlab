function clean_files()
%CLEAN_FILES Summary of this function goes here
%   Detailed explanation goes here

% Get all items in the current directory
folder_contents = dir;

allowed_ext = {'.env', '.ssp', '.bty', '.prt', '.shd', '.ray'};


for item = folder_contents' % Transpose to loop through items correctly

    % Skip if the item is a directory
    if item.isdir
        continue;
    end

    % Get file extension
    [~, ~, file_ext] = fileparts(item.name);

    % Check if extension is allowed
    if any(strcmpi(file_ext, allowed_ext))
        fprintf('Deleting file: %s\n', item.name);
        delete(item.name);
    end
end



end