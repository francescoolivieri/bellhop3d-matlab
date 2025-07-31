function clean_files()
%CLEAN_FILES Summary of this function goes here
%   Detailed explanation goes here

% Get all items in the current directory
folder_contents = dir;

% Loop through each item
for item = folder_contents' % Transpose to loop through items correctly

    % Skip if the item is a directory
    if item.isdir
        continue;
    end

    % Get the filename without its extension
    [~, file_name_only, ~] = fileparts(item.name);

    % Check if the filename is exactly 7 digits using a regular expression
    if ~isempty(regexp(file_name_only, '^\d{7}$', 'once'))

        % If it matches, delete the file and notify the user
        fprintf('Deleting file: %s\n', item.name);
        delete(item.name);

    end
end


end