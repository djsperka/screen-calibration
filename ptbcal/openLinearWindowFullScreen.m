function [windowIndex, windowRect] = openLinearWindowFullScreen(screen, calfile, b255)
%openLinearWindowFullScreen Opens a full screen window with an inverse
%gamma table taken from the calfile. If all goes well, this screen will
%provide linear outputs. If b255 is true, use r,g,b color values in the
%range 0-255. If b255 is false (the default), colors use the range 0-1.
%   Detailed explanation goes here

    arguments
        screen (1,1) {mustBeNumeric},
        calfile char {mustBeFile},
        b255 {mustBeNumericOrLogical} = false   
    end

    % cal file
    cal = myLoadCalFile(calfile);

    % inverse gamma
    igamma = InvertGammaTable(cal.gammaInput, cal.gammaTable, 1024);

    % open window
    PsychDefaultSetup(2);
    if ~b255
        [windowIndex, windowRect] = PsychImaging('OpenWindow', screen, .5);
        fprintf('Use floating point range 0.0-1.0 for colors in this window.\n');
    else
        [windowIndex, windowRect] = Screen('OpenWindow', screen, 127);
        fprintf('Use uint8 range 0-255 for colors in this window.\n');
    end

    % now load inverse gamma table
    Screen('LoadNormalizedGammaTable', windowIndex, igamma, 0);
    Screen('Flip', windowIndex);

end

