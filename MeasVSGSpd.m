function [spd,S] = MeasVSGSpd(settings, S, syncMode, whichMeterType)
% [spd,S] = MeasMonSpd(window, settings, [S], [syncMode], [whichMeterType], [bitsppClut])
%MeasVSGSpd([0 0 0]', cal.describe.S, 0, whichMeterType);
% Measure the Spd of a series of monitor settings.
%
% This routine is specific to go with CalibrateMon,
% as it depends on the action of SetMon. 
%
% If whichMeterType is passed and set to 0, then the routine
% returns random spectra.  This is useful for testing when
% you don't have a meter.
%
% Other valid types:
%  1 - Use PR650 (default)
%  2 - Use CVI
%
% Check args and make sure window is passed right.
usageStr = 'Usage: [spd,S] = MeasVSGSpd(settings, [S], [syncMode], [whichMeterType])';
if nargin < 1 || nargin > 4 || nargout > 2
	error(usageStr);
end

% Set defaults
defaultS = [380 5 81];
defaultSync = 'on';
defaultWhichMeterType = 1;  % default is PR650

% Check args and set defaults
if nargin < 4 || isempty(whichMeterType)
	whichMeterType = defaultWhichMeterType;
end
if nargin < 3 || isempty(syncMode)
    % FIXME: Not used? MeasSpd() would accept it as argument.
	syncMode = defaultSync;
end
if nargin < 2 || isempty(S)
	S = defaultS;
end

[null, nMeas] = size(settings); %#ok<*ASGLU>
spd = zeros(S(3), nMeas);
for i = 1:nMeas

    fprintf('making measurement %d..., color (%g, %g, %g)\n', i, settings(1,i), settings(2, i), settings(3, i));
    
    % Set the color.
    calDispPatch(settings(:, i)');

    % Measure spectrum
    if (whichMeterType == 1)
        spd(:, i) = old650measspd(S,'on');
    else
        spd(:,i) = MeasSpd(S, whichMeterType, syncMode);
    end
end
