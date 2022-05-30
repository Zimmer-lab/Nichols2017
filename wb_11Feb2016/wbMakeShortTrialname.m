function shortTrialname=wbMakeShortTrialname(trialname)

    if strfind(trialname,'_')
        shortTrialname=trialname(1:strfind(trialname,'_')-1);
    else
        shortTrialname=trialname;
    end
    
end
