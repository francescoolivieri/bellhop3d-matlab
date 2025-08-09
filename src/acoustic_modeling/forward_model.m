function tl = forward_model(map, pos, s)
% FORWARD_MODEL  Wrapper kept for backward compatibility.
%   Delegates to uw.internal.ForwardModel.computeTL.

tl = uw.internal.ForwardModel.computeTL(map, pos, s);
end

