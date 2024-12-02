function [windowPtr,windowRect] = openGammaWindow(calfile,screenid,bkgd,rect)
%UNTITLED5 Summary of this function goes here
%   PsychDefaultSetup should be called before calling this.

    arguments
        calfile char
        screenid double
        bkgd (1, 3) double = [.5, .5, .5]
        rect double = []
    end

    [calFileFolder, base, ext] = fileparts(calfile);
    calFileBase = [base, ext];
    cal = LoadCalFile(calFileBase, Inf, calFileFolder);
    if isempty(cal)
        throw MException('openGammaWindow:CalFileNotFound', 'Check file and folder for cal file');
    end


    % open window
    [windowPtr, windowRect] = PsychImaging('OpenWindow', screenid, bkgd, rect);

    % Get inverse gamma table to do linearization ...
    iGammaTable = InvertGammaTable(cal.gammaInput, cal.gammaTable, 256);

    % Backup cluts, RestoreCluts() will restore, done automatically by
    % sca.
    BackupCluts();

    % And load the gamma table
    Screen('LoadNormalizedGammaTable', screenid, iGammaTable);

end