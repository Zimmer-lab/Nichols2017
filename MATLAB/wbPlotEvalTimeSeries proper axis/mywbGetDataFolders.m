

function FolderList = mywbGetDataFolders

Folders = dir;

FolderList = cell(1,1);

cnt = 0;

for i = 1:length(Folders)
    
   
    
    if (Folders(i).isdir & ~strcmp(Folders(i).name,'.')) & ~strcmp(Folders(i).name,'..')
        
        if  isempty(strfind(Folders(i).name,'&'))
            
             cnt = cnt +1;
             
             FolderList{cnt} = Folders(i).name;


        elseif strfind(Folders(i).name,'&') ~= 1;
            
               cnt = cnt +1;
               
               FolderList{cnt} = Folders(i).name;

        end
        
    end
    
   
    
end

end



