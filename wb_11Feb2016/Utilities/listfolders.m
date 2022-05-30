function names=listfolders(dirname,fullPathFlag,upOneLevelFlag)
%names=listfolders(dirname,fullPathFlag)
%
%ignores folders with & sign
%
if nargin<1 || isempty(dirname)
    dirname=pwd;
end

if nargin<2
    fullPathFlag=false;
end

if nargin<3
    upOneLevelFlag=false;
end

if upOneLevelFlag
    
    slashes=strfind(dirname,filesep);
    dirname=dirname(1:slashes(end)-1);
    
end

d=dir(dirname); 

    
j=1;
for i=1:length(d)
    if isempty(strfind(d(i).name,'.')) && isempty(strfind(d(i).name,'&'))
        if fullPathFlag
            names{j}=[dirname filesep d(i).name];
        else
            names{j}=d(i).name;
        end
        j=j+1;
    end
end


if ~exist('names','var')
    names=[];
end