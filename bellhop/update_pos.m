function [r_child, z_child] = update_pos(r_parent, z_parent,s, action)

    dz=[-1 0 1 -1 0 1 -1 0 1].*s.d_z;
    dr=[1 1 1 0 0 0 -1 -1 -1].*s.d_r;

    r_child=dr(action)+r_parent;
    z_child=dz(action)+z_parent;

    if z_child>s.z_max || z_child<s.z_min || r_child<s.r_min || r_child>s.r_max 
    r_child=nan;
    z_child=nan;
    end


end

