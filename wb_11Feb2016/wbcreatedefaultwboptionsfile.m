function wboptions=wbcreatedefaultwboptionsfile(version)

     if nargin<1
         version='v1';
     end

     if strcmp(version,'v2')
        exampleFileName='example wboptions v2.mat';
     else
        exampleFileName='example wboptions.mat';
     end
        
     wbpath=which('wb');
     seps=strfind(wbpath,filesep);
     wbfolder=wbpath(1:seps(end));
     
     
     load([wbfolder exampleFileName]);
     clear wbpath;
     clear wbfolder;
     clear seps;
     save('wboptions.mat');
     
     wbpath=which('wb');
     seps=strfind(wbpath,filesep);
     wbfolder=wbpath(1:seps(end)); 
     wboptions=load([wbfolder exampleFileName]);

end
