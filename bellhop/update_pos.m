function [x_child, y_child, z_child] = update_pos(x_parent, y_parent, z_parent,s, action)

    dz=[-1 0 1 -1 0 1 -1 0 1].*s.d_z;
    dx=[-1 -1 -1 0 0 0 1 1 1].*s.d_x;
    dy=[-1 0 1 -1 0 1 -1 0 1].*s.d_y;

    % Apply movement
    x_child=dx(action)+x_parent;
    y_child=dy(action)+y_parent;
    z_child=dz(action)+z_parent;

    if z_child>s.z_max || z_child<s.z_min || x_child<s.x_min || x_child>s.x_max || y_child<s.y_min || y_child>s.y_max 
        x_child=nan;
        y_child=nan;
        z_child=nan;
    end

end

