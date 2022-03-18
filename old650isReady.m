function [ready] = old650isReady()
%old650isReady Check whether pr650 is initialize and ready for use.
%   Detailed explanation goes here

global g_650;

ready = 1;

% Check for initialization
if isempty(g_650) || ~isvalid(g_650)
    ready = 0;
end
return;

