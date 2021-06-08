function [readStr] = myPR650rawspd(timeout)
%MYPR650RAWSPD Summary of this function goes here
%   Detailed explanation goes here
global g_650;

% Check for initialization
if isempty(g_650) || ~isvalid(g_650)
  error('Meter has not been initialized.');
end

% flush
flush(g_650);

% Make measurement
writeline(g_650, 'M5');

% get response, allow 2 minutes for measurement. This may need adjustment
% if the number of samples is changed. 
readStr = old650getresult(120);
if length(readStr) == 0
  error('No response after measure command');
end


return;
