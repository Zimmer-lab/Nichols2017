function  outp_cellarray=ForEachFolder(folderList,func_handle,func_options,closeFigureFlag)
%outp_cellarray=ForEachFolder(folderList,func_handle,func_options)
%example:
%outp=ForEachFolder(folderList,@wbComputePCA,{[],wbPCADefaultOptions)

if nargin<1 || isempty(folderList)
    folderList=listfolders(pwd,true);
end

if nargin<2 || isempty(func_handle)
    func_handle=@folderinfo;
end

if nargin<3
    func_options=[];
end

if nargin<4
    closeFigureFlag=true;
end

originalFolder=pwd;

outp_cellarray=[];

for i=1:length(folderList)
    
    thisfolder=folderList{i};
    disp(['ForEachFolder> processing ' thisfolder]);
    cd(thisfolder);
    try
        if ~isempty(func_options)
            
            if length(func_options)==4
                 if nargout(func_handle)>0
                    outp_cellarray{i}=func_handle(func_options{1},func_options{2},func_options{3},func_options{4});
                else
                    func_handle(func_options{1},func_options{2},func_options{3});
                end    
              
            elseif length(func_options)==3
                 if nargout(func_handle)>0
                    outp_cellarray{i}=func_handle(func_options{1},func_options{2},func_options{3});
                else
                    func_handle(func_options{1},func_options{2},func_options{3});
                end               
                
            elseif length(func_options)==2
                
                if nargout(func_handle)>0
                    outp_cellarray{i}=func_handle(func_options{1},func_options{2});
                else
                    func_handle(func_options{1},func_options{2});
                end
                
            else
                if nargout(func_handle)>0
                    outp_cellarray{i}=func_handle(func_options);
                else
                    func_handle(func_options);
                end
            end
            
        else
            
            if nargout(func_handle)>0
                outp_cellarray{i}=func_handle();
            else
                func_handle();
            end
        end
    catch err;
        disp(err.message);
        disp('ForEachFolder> failed on this directory. moving on.');
    end
    
    if closeFigureFlag
        close all;
    end
    
end

cd(originalFolder);

end
