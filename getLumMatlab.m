function [lum] = getLumMatlab(varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

p = inputParser;
colorOK = @(x) isnumeric(x) && (size(x, 2) == 0 || ((size(x, 2) == 1 || size(x, 2) == 3) && sum(reshape(x, 1, [])>=0)==length(reshape(x, 1, [])) && sum(reshape(x, 1, [])<=1)==length(reshape(x, 1, []))));
addRequired(p, 'gamma', @(x) isstring(x) && exist(strcat(x, ".vsg"))==2 && exist(strcat(x, ".mat"))==2);
addParameter(p, 'color', [.5 .5 .5], colorOK);
addParameter(p, 'pr650', 0, @isscalar);
parse(p, varargin{:});

% check if pr650 is ready...if needed

if p.Results.pr650 && old650isReady()    
    % load calibration matrix file
    [ frompath, basename, ext] = fileparts(calfile);
    fprintf(1,'\nLoading cal \"%s\" from folder %s\n', basename, frompath);
    cal = LoadCalFile(basename, [], frompath);
    
    % get stuff for computing luminance
    load T_cones_ss2
    load T_ss2000_Y2
    S_cones = S_cones_ss2;
    T_cones = T_cones_ss2;
    T_Y = 683*T_ss2000_Y2;
    S_Y = S_ss2000_Y2;
    T_Y = SplineCmf(S_Y,T_Y,S_cones);

    calLum = SetSensorColorSpace(cal,T_Y,S_Y);
end

% init vsg
fprintf('Initializing VSG.\n');
global CRS;
if ~isstruct(CRS)
  crsLoadConstants;
end
vsgInit;
pause('on');
pause(2);
pause('off');

displayPage = 1;
drawPage = 2;

% load gamma table, then set mode
fprintf('Read gamma table from %s\n', strcat(p.Results.gamma, ".vsg"));
fid = fopen(strcat(p.Results.gamma, ".vsg"));
dummy = fread(fid, [5, 1], 'double');
rGamma = fread(fid, [crsGetColourResolution, 1], 'uint16'); 
gGamma = fread(fid, [crsGetColourResolution, 1], 'uint16'); 
bGamma = fread(fid, [crsGetColourResolution, 1], 'uint16'); 
fclose(fid);
fprintf('Load gamma profile\n');
crsGAMMAloadProfile(rGamma/65535, gGamma/65535, bGamma/65535);
fprintf('Set 24 bit color mode\n');
crsSet24bitColourMode;
fprintf('done.\n');

% create matrix for setting full screen color
W = crsGetScreenWidthPixels;
H = crsGetScreenHeightPixels;
M = ones(H, W, 3);


% loop through colors
colors = p.Results.color;
if size(colors, 2) == 0
    colors = [.5 .5 .5];    
end

for irow=1:size(colors, 1)
    if size(colors, 2) == 3
        c = colors(irow, :);
    else
        c = [colors(irow) colors(irow) colors(irow)];
    end
    M(:, :, 1) = c(1);
    M(:, :, 2) = c(2);
    M(:, :, 3) = c(3);
    crsDrawMatrix24bitColour(M);
    
    % page is drawn, flip page.
    crsSetDisplayPage(drawPage);
    crsSetDrawPage(displayPage);
    tmp = displayPage;
    displayPage = drawPage;
    drawPage = tmp;
    
    if p.Results.pr650
        [spd, qual] = old650measspd();
        lum = T * spd;
        fprintf('color (%f, %f, %f), lum %f\n', c(1), c(2), c(3), lum);
    else
        fprintf('color (%f, %f, %f), lum <PR650 NOT READY>\n', c(1), c(2), c(3));
        pause('on');
        pause(2);
        pause('off');
    end
end


% % set color
% H = crsGetScreenHeightPixels;
% W = crsGetScreenWidthPixels;
% M = zeros(H, W, 3);
% M(:, :, 1) = color(1);
% M(:, :, 2) = color(2);
% M(:, :, 3) = color(3);
% crsDrawMatrix24bitColour(M);
% 
% % if pr650 is ready, measure lum
% lum = -1;
% if pr650Ready
%     spd = old650measspd();
% end 

return;
end
