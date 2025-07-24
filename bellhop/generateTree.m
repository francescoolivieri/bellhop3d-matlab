function tree = generateTree(depth)
    branches = 9; % number of branches at each node
    if depth == 0
        % Base case (leaf node)
        tree.actions = [];
        tree.x=[];
        tree.y=[];
        tree.z=[];
        tree.mu = [];
        tree.Sigma = [];
    else
        % Internal node
        for k = 1:branches
            % Recursively generate subtrees
            tree.branch(k) = generateTree(depth - 1);
        end
    end
end