function [lum] = measureLuminance(windowIndex,color,S,T)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    Screen('FillRect', windowIndex, color);
    Screen('Flip', windowIndex);
    [spd,~] = old650measspd(S,'on');
    lum = T*spd;

end