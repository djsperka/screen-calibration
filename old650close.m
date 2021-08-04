function [] = old650close()
%OLD650CLOSE Close serial connection to PR650.
%   If the PR650 has been opened, the the spectrometer is reset, and the 
%   serial connection is terminated.

global g_650;

% check if global is nonempty or valid
if isempty(g_650) || ~isvalid(g_650)
    g_650 = [];
else
    % reset
    setRTS(g_650, true);
    pause(0.1);
    setRTS(g_650, false);

    delete(g_650);
    g_650 = [];
end

return
