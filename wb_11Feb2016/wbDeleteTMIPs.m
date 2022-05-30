function wbDeleteTMIPs(mainfolder)

    if nargin<1
        mainfolder=pwd;
    end

    rmdir([mainfolder filesep 'TMIPs'],'s');

end