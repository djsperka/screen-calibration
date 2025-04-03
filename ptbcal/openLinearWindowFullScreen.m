function [windowIndex, windowRect] = openLinearWindowFullScreen(screen, calfile, b255, bkgd)
%openLinearWindowFullScreen Opens a full screen window with an inverse
%gamma table taken from the calfile. If all goes well, this screen will
%provide linear outputs. If b255 is true, use r,g,b color values in the
%range 0-255. If b255 is false (the default), colors use the range 0-1. The
%background color can be a single scalar value or a color triplet. 
%   Detailed explanation goes here

    arguments
        screen (1,1) {mustBeNumeric},
        calfile char {mustBeFile},
        b255 {mustBeNumericOrLogical} = false,
        bkgd {mustBeColor} = 0.5
    end


    % figure out how to deal with the bkgd we were given.
    isSmall = all(bkgd<=1);

    % open window
    PsychDefaultSetup(2);
    if ~b255
        if isSmall
            useBkgd = bkgd;
        else
            useBkgd = bkgd/255;
        end
        [windowIndex, windowRect] = PsychImaging('OpenWindow', screen, useBkgd);
        fprintf('\nBackground color is %s\n', formatColor(useBkgd));
        fprintf('Use floating point range 0.0-1.0 for colors in this window.\n');
    else
        if isSmall
            useBkgd = bkgd*255;
        else
            useBkgd = bkgd;
        end
        [windowIndex, windowRect] = Screen('OpenWindow', screen, useBkgd);
        fprintf('\nBackground color is %s\n', formatColor(useBkgd));
        fprintf('Use uint8 range 0-255 for colors in this window.\n');
    end

    % cal file
    cal = myLoadCalFile(calfile);

    % inverse gamma
    igamma = InvertGammaTable(cal.gammaInput, cal.gammaTable, 1024);

    % now load inverse gamma table
    Screen('LoadNormalizedGammaTable', windowIndex, igamma, 0);
    Screen('Flip', windowIndex);

    fprintf('Inverse gamma loaded and in use for this window.\n');

end

function mustBeColor(c)
    assert(isnumeric(c) && isvector(c) && ismember(length(c), [1,3]));
end

% assume scalar or 3-element vector
function [str] = formatColor(vecOrScalar)
    if length(vecOrScalar)==1
        str = sprintf('[%f]', vecOrScalar);
    else
        str = sprintf('[%f,%f,%f]', vecOrScalar(1), vecOrScalar(2), vecOrScalar(3));
    end
end
            