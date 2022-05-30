function metadata=wbcreatedefaultmetafile

     wbpath=which('wb');
     seps=strfind(wbpath,filesep);
     wbfolder=wbpath(1:seps(end));
     load([wbfolder 'example meta.mat']);
     clear wbpath;
     clear wbfolder;
     clear seps;
     dataFolder=pwd;
     save('meta.mat');
     
     wbpath=which('wb');
     seps=strfind(wbpath,filesep);
     wbfolder=wbpath(1:seps(end)); 
     dataFolder=pwd;
     metadata=load([wbfolder 'example meta.mat']);

end