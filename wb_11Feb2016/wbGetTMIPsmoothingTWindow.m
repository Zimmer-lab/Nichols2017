function result=wbGetTMIPsmoothingTWindow(mainfolder)

    %pull smoothingTWindow from filename of TMIPs
    
    if nargin<1
        mainfolder=pwd;
    end
    
       try
     
            dirresult=dir([mainfolder filesep 'TMIPs' filesep 'Z01' filesep '*.tif']);
            filename=dirresult(1).name;

            dashLocations=findstr('-',filename);
            valueStringStart=findstr('TW',filename)+2;
            valueStringEnd=dashLocations(find(dashLocations>valueStringStart,1,'first'))-1;
            filename(valueStringStart:valueStringEnd);
            result=str2num(filename(valueStringStart:valueStringEnd));
        
       catch
            result=0;
       end
end
