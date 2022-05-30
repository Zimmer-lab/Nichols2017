function wbstruct=wbAddStateParams(wbstructOrFileName,verboseMode)


if nargin<2 || isempty(verboseMode)
    verboseMode=true;
end

if nargin<1 || isempty(wbstructOrFileName)
    [wbstruct wbstructFileName]=wbload([],false);
elseif ischar(wbstructOrFileName)
        [wbstruct wbstructFileName]=wbload(wbstructOrFileName,false);
else
    wbstruct=wbstructOrFileName;
end

saveFlag=false;

% create wbstruct.simple.stateParams using defaults if it doesn't exist
if ~isfield(wbstruct.simple,'stateParams')
    disp('wbAddStateParams> creating new wbstruct.simple.stateParams array.');
    wbstruct.simple.stateParams=repmat([0.05 0.3]',1,wbstruct.simple.nn);
    saveFlag=true;
end

if size(wbstruct.simple.stateParams,1)==2   
    %add flag for ForceNoPlateaus
    wbstruct.simple.stateParams=[wbstruct.simple.stateParams; zeros(1,size(wbstruct.simple.stateParams,2))];
    saveFlag=true;
end

if size(wbstruct.simple.stateParams,1)==3  
    %add two more flags
    wbstruct.simple.stateParams=[wbstruct.simple.stateParams; ones(1,size(wbstruct.simple.stateParams,2)); ones(1,size(wbstruct.simple.stateParams,2))];
    saveFlag=true;
end


if size(wbstruct.simple.stateParams,2)<size(wbstruct.simple.deltaFOverF,2)  
    %add new StateParam entries for added neurons
    numToAdd=size(wbstruct.simple.deltaFOverF,2) - size(wbstruct.simple.stateParams,2);
    wbstruct.simple.stateParams=[wbstruct.simple.stateParams, repmat([0.05 0.3 0 1 1]',1,numToAdd) ];
    saveFlag=true;
end

if saveFlag && exist('wbstructFileName','var')
    save(wbstructFileName,'-struct','wbstruct');
    if verboseMode
        disp('wbAddStateParams> wbstruct saved.')
    end
elseif verboseMode
    disp('wbAddStateParams> no updates needed.');
end