function [spd] = djsMeasSpdAtColors(windowIndex, colors)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    whichMeterType = 1;     % We are using PR-650
    syncMode = 'off';
    S = [380 5 81];         % wl sampling for PR-650
    nColors = size(colors, 1);% 
    
    % colors should be Nx3; columns are r,g,b respectively.    
    
    spd = zeros(S(3), nColors);
    for i = 1:nColors
    
        Screen('FillRect', windowIndex, colors(i,:));
        Screen('Flip', windowIndex);
        spd(:,i) = MeasSpd(S, whichMeterType, syncMode);
    
    end
end