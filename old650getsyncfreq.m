function freq = old650getsyncfreq()
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

global g_650;

% Check for initialization
if isempty(g_650) || ~isvalid(g_650)
  error('Meter has not been initialized.');
end

% flush buffers
flush(g_650);

% Write F command
writeline(g_650, 'F');

% get response, allow 10s. This may need adjustment.
readStr = old650getresult(10, 1);
if length(readStr) == 0
  error('No response after measure command');
end
fprintf('response: %s\n', readStr);

% Parse return
qual = -1;
[raw, count] = sscanf(readStr,'%f,%f',2);
if count == 2
  qual = raw(1);
  freq = raw(2);
end

if qual ~= 0
  freq = [];
end


end

