function result=wbCheckForDataFolder(folder,verboseFlag,wbCheckFlag)

if nargin<3
    wbCheckFlag=false;
end

if nargin<2
    verboseFlag=false;
end

if nargin<1 || isempty(folder)
    folder=pwd;
end

if (isempty(dir([folder filesep '*.tif*'])) && ~exist('TMIPs','dir')) || (~exist('Quant','dir') && wbCheckFlag)
    if verboseFlag
        disp('wbCheckForDataFolder> No .tif files or TMIPs folder found. This is probably not a wbstruct data folder.');
    end
    result=0;
else
    result=1;
end