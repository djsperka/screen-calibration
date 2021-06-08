function spd = old650parsespdstr(readStr, S)
%old650parsespdstr Summary of this function goes here
%   Detailed explanation goes here

% spd = PR650parsespdstr(readStr,S)
%
% Parse the spectral power distribution string
% returned by the PR650.
% Modified PTB function to work with new functions. The value of strings
% read omit the terminators, so the str2num call below is slightly
% different. 

if nargin < 2 || isempty(S)
	S = [380 5 81];
end

readCharVec = '';
if isstring(readStr)
    readCharVec = convertStringsToChars(readStr);
else
    readCharVec = readStr;
end

istart = strfind(readStr,'0380.');

for k= 1:101
	spd(k) = str2num(readCharVec(istart+6+15*(k-1):istart+15*k-1));
end

% Convert to our units standard.
spd = 4 * spd';

% Spline to desired wavelength sampling.
spd = SplineSpd([380 4 101], spd, S);

