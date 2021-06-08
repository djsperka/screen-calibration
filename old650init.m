function retval = myPR650init(comPort)
% retval = myPR650init(comPort)
% 
% Initialize serial port for talking to PR650. 
%
% 'enableHandshaking' allows you to enable handshaking.  By default,
% handshaking is disabled.  To enable handshaking, set this value to 1 or
% true.
%
% This version modified from PTB version 6/2/2021 djs
% IOPort not working at all, manual approach using serialport used here.
%
% 11/26/07    mpr   added timeout if nothing is returned within 10 seconds.
%
 
global g_650;
line=0;
line=[];
% Only open if we haven't already.
if isempty(g_650) || ~isvalid(g_650)
    g_650 = serialport('com1', 9600, 'Timeout', 5);
    configureTerminator(g_650, 'CR');

    % put into remote mode
    setRTS(g_650, true);
    pause(0.1);
    setRTS(g_650, false);
    pause(3.0);

    % send command
    writeline(g_650, 'B1');

    % read response
    setDTR(g_650, true);
    line = readline(g_650);
    setDTR(g_650, false);

end

if (~isempty(strfind(line, '000')))
    retval = 1;
end
return;