function old650flush()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

global g_650;

% Check for initialization
if isempty(g_650) || ~isvalid(g_650)
  error('Meter has not been initialized.');
end

flush(g_650);

end

