function [result] = old650getresult(timeout, nLinesToRead)
%old650getresult Reads a result from the PR650.
%   Timeout is the timeout for first read. Subsequent reads, if any, use
%   short timeout. If number of lines to read is known, provide that.
%   Otherwise will read until a timeout occurs. 
%   Returns a string array, split at terminators.

global g_650;
if nargin <2
    nLinesToRead = inf;
end
if nargin < 1
    timeout = 5;
end

% Check for initialization
if isempty(g_650) || ~isvalid(g_650)
  error('Meter has not been initialized.');
end

% set DTR, timeout and start reading/waiting. 
nLines = 0;
g_650.Timeout = timeout;
setDTR(g_650, true);
sline = readline(g_650);
nLines = 1;

% read lines until we cannot. Short timeout here. 
% this should work for single line and multi-line responses. 
result = sline;
if length(result) > 0
    while nLines < nLinesToRead || nLinesToRead == 0
        g_650.Timeout = 1;
        sline = readline(g_650);
        if length(sline) == 0
            break;
        else
            nLines = nLines + 1;
        end
        result = [result sline];
    end
end
setDTR(g_650, false);
return;
