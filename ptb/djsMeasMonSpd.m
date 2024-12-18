function [spd,S] = djsMeasMonSpd(window, settings, S, syncMode, whichMeterType, theClut)
% [spd,S] = MeasMonSpd(window, settings, [S], [syncMode], [whichMeterType], [theClut])
%
% Measure the Spd of a series of monitor settings.
%
% This routine is specific to go with CalibrateMon,
% as it depends on the action of SetMon. 
%
% If whichMeterType is passed and set to 0, then the routine
% returns random spectra.  This is useful for testing when
% you don't have a meter.
%
% Other valid types: See list in 'help CMCheckInit' for various Photo Research
% PR-xxx colormeters.
%

% 10/26/93  dhb   Wrote it based on ccc code.
% 11/12/93  dhb   Modified to use SetColor.
% 8/11/94   dhb   Sync mode.
% 8/15/94   dhb   Sync mode as argument, allow S to be [] for default.
% 4/12/97   dhb   New toolbox compatibility, take window and bits args.
% 8/26/97   dhb   pbe Add noMeterAvail arg.
% 4/7/99    dhb   Add argument for radius board. Compact default arg code.
% 8/14/00   dhb   Call to CMETER('SetParams') conditional on OS9.
% 8/20/00   dhb   Remove bits arg to SetColor.
% 8/21/00   dhb   Remove dependence on RADIUS flag.  This is now handled inside of SetColor.
%           dhb   Change calling conventions to remove unused args.
% 9/14/00   dhb   Sync mode is not actually used.  Arg still passed for backwards compat.
% 2/27/02   dhb   Change noMeterAvail to whichMeterType.
% 8/19/12   mk    Rewrite g_usebitspp path to use PTB imaging pipeline for higher robustness 
%                 and to support more display devices.
% 6/30/23   mk    Use new clut mapping to fix this mess on standard gpus.

% Declare Bits++ box global
global g_usebitspp;

% If the global flag for using Bits++ is empty, then it hasn't been
% initialized and default it to 0.
if isempty(g_usebitspp)
    g_usebitspp = 0;
end

% Check args and make sure window is passed right.
usageStr = 'Usage: [spd,S] = MeasMonSpd(window, settings, [S], [syncMode], [whichMeterType])';
if nargin < 2 || nargin > 6 || nargout > 2
    error(usageStr);
end
if size(window,1) ~= 1 || size(window,2) ~= 1
    error(usageStr);
end

% Set defaults
defaultS = [380 5 81];
defaultSync = 'on';
defaultWhichMeterType = 1;

% Check args and set defaults
if nargin < 5 || isempty(whichMeterType)
    whichMeterType = defaultWhichMeterType;
end
if nargin < 4 || isempty(syncMode)
    syncMode = defaultSync;
end
if nargin < 3 || isempty(S)
    S = defaultS;
end


dMMSStart = tic();


[null, nMeas] = size(settings); %#ok<*ASGLU>
spd = zeros(S(3), nMeas);
for i = 1:nMeas
    % Set the color.
    theClut(2,:) = settings(:, i)';
    Screen('LoadNormalizedGammaTable', window, theClut, 2);
    Screen('Flip', window, 0, 1);

    % Measure spectrum
    switch whichMeterType
        case 0
            spd(:,i) = sum(settings(:, i)) * ones(S(3), 1);
            WaitSecs(0.1);
        case 2
            error('CVI interface not yet ported to PTB-3.');
            % cviCal = LoadCVICalFile;
            % spd(:,i) =  CVICalibratedDarkMeasurement(cviCal, S, [], [], [], window, 1, settings(:,i));
        otherwise
            tstart = tic;
            spd(:,i) = MeasSpd(S, whichMeterType, syncMode);
            telapsed = toc(tstart);
            fprintf('djsMeasMonSpd %d/%d: type %d on? %s took %.1f s\n', i, nMeas, whichMeterType, syncMode, telapsed);
    end
end
