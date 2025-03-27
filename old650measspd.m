function [spd, qual] = old650measspd(S,syncMode)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

global g_650;

% Check for initialization
if isempty(g_650) || ~isvalid(g_650)
  error('Meter has not been initialized.');
end

% only use these parameters. 
% S = [380 5 81];
% syncMode = 'on';

% TODO set sync mode
syncFreq = 0;
if syncMode == 'on'
    syncFreq = old650getsyncfreq();
    if isempty(syncFreq)
        fprintf('Cannot sync, will measure without sync\n');
    else
        fprintf('Using measured sync frequency: %f\n', syncFreq);
    end
end

% Flushing buffers.
old650flush();

rawspd = old650rawspd(120);
if length(rawspd) == 0
  error('No response after measure command');
end
if length(rawspd) ~= 103
    error('Expected 103 lines in response, got %d', length(rawspd));
end

% from PR650measspd
qual = sscanf(rawspd(1),'%f', 1);
fprintf('Got qual code of %d.\n',qual);
	 
% Check for sync mode error condition.  If get one,
% turn off sync and try again.
if qual == 7 || qual == 8
    fprintf('Got qual code of %d, setting sync freq to 0 and trying again.\n',qual);
 	old650setsyncfreq(0);
    rawspd = old650rawspd(120);
    qual = sscanf(rawspd,'%f',1);
    fprintf('Retry returns quality code of %d\n',qual);
%     end
end
	
% Check for other error conditions
if qual == -1 || qual == 10
    fprintf('Low light level during measurement, returning zero.\n');
    spd = zeros(S(3), 1);
elseif qual == 18 || qual == 0
	spd = old650parsespdstr(rawspd, S);	
elseif qual ~= 0
  error('Bad return code %g from meter', qual);
end	




end

