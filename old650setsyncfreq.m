function old650setsyncfreq(freq)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

global g_650;

% Check for initialization
if isempty(g_650) || ~isvalid(g_650)
  error('Meter has not been initialized.');
end



% Set freq. If nonzero, setting freq to sync with. If zero, tells meter to
% not use sync.
if (freq ~= 0)
   cmd = ['s01,,,,' num2str(freq) ',0,01,1'];
else
   cmd = ['s01,,,,' ',0,01,1'];
end

% flush buffers
flush(g_650);

% Write command
writeline(g_650, cmd);

% response
response = old650getresult(10, 1);
if length(response) == 0
  error('No response after set sync command');
end
fprintf('response: %s\n', response);

qual = sscanf(response, '%f', 1);
if qual ~= 0
  fprintf('Return string was %s\n', response);
  error('Can''t set sync freq');
end

end

