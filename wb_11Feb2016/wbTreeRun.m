function [outp_cellarray, dirtree]=wbTreeRun(func_handle,rootfolder,func_options,depth,ampersandOverride)
%dirtree=wbtreerun(func_handle,rootfolder,func_options,depth)
%
%DON'T FORGET THE @ SIGN for your function handle
%
%execute a function or script in every folder of a folder tree
%exclude folders starting with an &
%
%Saul Kato

originalFolder=pwd;

if nargin<5 || isempty(ampersandOverride)
    ampersandOverride=false;
end

if nargin<4 || isempty(depth)
    depth=1;
end

if nargin<2 || isempty(rootfolder)
    rootfolder=pwd;
end

if nargin<1
    func_handle=@folderinfo;
end

j=1;
if depth==1
    dirfold=dir(rootfolder);
    for i=1:length(dirfold)
        if (dirfold(i).isdir) && ~strcmp(dirfold(i).name,'.') && ~strcmp(dirfold(i).name,'..')
            dirtree{j}=[pwd filesep dirfold(i).name];
            j=j+1;
        end
    end
    dirtree=dirtree';
else

    dirtree=wildcardsearch(rootfolder,'*/',true,true);   %return all subfolder names

end

%remove directories that contain & character
if ~ampersandOverride
    i=1;
    while i<(size(dirtree,1)+1)
        if ~isempty(strfind(dirtree{i},'&'))
            dirtree(i)=[];  %delete cell
            i=i-1;
        end
        i=i+1;
    end
end


outp_cellarray=ForEachFolder(dirtree,func_handle,func_options);

cd(originalFolder);

disp(['wbTreeRun> done.']);


end



