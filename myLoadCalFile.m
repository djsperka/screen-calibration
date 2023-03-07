function [cal] = myLoadCalFile(fullpathToCalFile)
%myLoadCalFile Load cal file using full path.
%   Standard PTB LoadCalFile function doesn't do this.

[frompath, basename, ext] = fileparts(fullpathToCalFile);
fprintf(1,'\nLoading cal \"%s\" from folder %s\n', basename, frompath);
cal = LoadCalFile(basename, [], frompath);

end