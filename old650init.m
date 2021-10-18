function retval = old650init(comPort)
% retval = old650init(comPort)
% 
% Initialize serial port for talking to PR650. 
%
% 'enableHandshaking' allows you to enable handshaking.  By default,
% handshaking is disabled.  To enable handshaking, set this value to 1 or
% true.
%
% This version modified from PTB version 6/2/2021 djs
% the PR650 functions in PTB do not work with our PR650. The communication
% method is wrong (maybe a firmware difference?), manual approach using 
% serialport used here. 
%
% 11/26/07    mpr   added timeout if nothing is returned within 10 seconds.
%
 
global g_650;
retval=0;
line=[];
% Only open if we haven't already.
if isempty(g_650) || ~isvalid(g_650)
    g_650 = serialport(comPort, 9600, 'Timeout', 5);
    configureTerminator(g_650, 'CR/LF', 'CR');

    % put into remote mode
    setRTS(g_650, true);
    pause(0.1);
    setRTS(g_650, false);
    pause(3.0);

    % send command
    writeline(g_650, 'B1');

    % read response
    line = old650getresult(30, 1);
    
    % pause a second
    pause(1);
    
    % now turn off backlight
    writeline(g_650, 'B0');
    line0 = old650getresult(30, 1);
    

end

if (contains(line(1), "000") && contains(line0(1), "000"))
    retval = 1;
end
return;