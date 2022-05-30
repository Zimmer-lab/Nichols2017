function [traceColoring, transitionListCellArray, transitionPreRunLengthArray,transitionRunLengthArray]=wbFourStateTraceAnalysis(wbstructOrFile,posThresh,negThresh,threshType,neuronNumbers,options)
%[traceColoring, transitionListCellArray,  transitionPreRunLengthArray]=wbFourStateTraceAnalysis(wbstructOrFile,posThresh,negThresh,threshType)
%or
%[traceColoring, transitionListCellArray,  transitionPreRunLengthArray]=wbFourStateTraceAnalysis(wbstructOrFile,'useSaved',neuronSubset)
%
%generate a four-state trace coloring and transition index list array, one
%column for each transition type.   Also compute the run length prior to
%each transition
%
%wbFourStateTraceAnalyis(wbstructOrFile,'useSaved',neuronString) will use saved
%parameters saved in wbstruct.simple.stateParams
%
%state list:
%1=valley  (down state)
%2=rise
%3=plateau (up state)
%4=fall
%
%transitionListArray transition types:
%col 1:    1->2  lo2rise
%col 2:    2->3  rise2hi
%col 3:    2->4  rise2fall   
%col 4:    3->4  hi2fall
%col 5:    4->1  fall2lo
%col 6:    4->2  fall2rise   %ELIMINATED BY forceTroughsFlag=true
%col 7:    2->1  rise2lo   %outlier transition
%col 8:    3->2  hi2rise %outlier transition
%col 9:    4->3  fall2hi %outlier transition
%col 10:   1->4  lo2fall %outlier transition         
%col 11:   1->3  lo2hi  %pathlogical transition
%col 12:   3->1  hi2lo  %pathological transition

%col 13:    all transitions

bufferMargin=.1;
smallRiseCutoff=.35;

if nargin<6
    options=[];
end

%unsaveable parameters
if ~isfield(options,'noHighTroughsFlag')
    options.noHighTroughsFlag=true;
end

if ~isfield(options,'noLowPlateausFlag')
    options.noLowPlateausFlag=true;
end

if ~isfield(options,'forceTroughsFlag')
    forceTroughsFlag=true;
else
    forceTroughsFlag=options.forceTroughsFlag;
end

if ~isfield(options,'forcePlateausFlag')
    forcePlateausFlag=true;
else
    forcePlateausFlag=options.forcePlateausFlag;
end





if nargin<1 || isempty(wbstructOrFile)
    [wbstruct, wbstructFileName]=wbload([],false);
elseif ischar(wbstructOrFile)
    [wbstruct, wbstructFileName]=wbload(wbstructOrFile,false);
else
    wbstruct=wbstructOrFile;  %wbstructFileName not assigned
end

nn=wbstruct.simple.nn;

%saved parameters
if ~isfield(options,'fixBadTransitionsFlag')
    fixBadTransitionsFlag=true(1,nn);
else
    fixBadTransitionsFlag=options.fixBadTransitionsFlag;
end

if ~isfield(options,'noFallToPlateauFlag')
    noFallToPlateauFlag=true(1,nn);
else
    noFallToPlateauFlag=options.noFallToPlateauFlag;
end

if ~isfield(options,'forceNoPlateausFlag')
    forceNoPlateausFlag=false(1,nn);
else
    forceNoPlateausFlag=options.forceNoPlateausFlag;
end


if ~exist('threshType','var') || isempty(threshType)
   threshType='rel';
end
      
if ~exist('posThresh','var') || isempty (posThresh)
   posThresh=.05*ones(1,nn); %0.006 is a good abs setting;
end
         
if ~exist('negThresh','var') || isempty (negThresh)
   negThresh=.3*ones(1,nn); %-0.006 is a good abs setting; %this should be a negative value
end

%parse useSaved option
if ischar(posThresh) 
    if strcmpi(posThresh,'USESAVED')  %ignore case
        threshType='rel';    
        if nargin==3
            neuronNumbers=negThresh;
        end
        
        if ~isfield(wbstruct.simple,'stateParams')
            wbstruct=wbAddStateParams(wbstruct);
        end
        
        posThresh=wbstruct.simple.stateParams(1,:);
        negThresh=wbstruct.simple.stateParams(2,:);
        if size(wbstruct.simple.stateParams,1)>2
            forceNoPlateausFlag=wbstruct.simple.stateParams(3,:);
        end
        if size(wbstruct.simple.stateParams,1)>3
            noFalltoPlateauFlag=wbstruct.simple.stateParams(4,:);
        end      
        if size(wbstruct.simple.stateParams,1)>4
            fixBadTransitionsFlag=wbstruct.simple.stateParams(5,:);
        end
        
        
    else
        disp('wbFourStateTraceAnalysis: second param not recognized.')
    end
else
    if isscalar(posThresh)
        posThresh=posThresh*ones(1,nn);
    end
    if isscalar(negThresh)
        negThresh=negThresh*ones(1,nn);
    end
    
end

if ~exist('neuronNumbers','var') 
    neuronNumbers=1:nn;
end

if ischar(neuronNumbers)
    [~,~,neuronNumbers]=wbgettrace(neuronNumbers,wbstruct);
elseif iscell(neuronNumbers)
    [~,neuronNumbers]=wbGetTraces(wbstruct,false,[],neuronNumbers);
end


if isfield(wbstruct.simple,'derivs')
    derivs=wbstruct.simple.derivs.traces(:,neuronNumbers);
else
    disp('wbFourStateTraceAnalysis: no derivs computed.  running wbAddDerivs.');
    if exist('wbstructFileName','var')
        disp(['Adding derivs to ' wbstructFileName]);
        wbAddDerivs(wbstructFileName);      
    else
        wbAddDerivs;
    end
    [wbstruct, wbstructFileName]=wbload([],false);
    derivs=wbstruct.simple.derivs.traces(:,neuronNumbers);
end

traces=wbstruct.simple.deltaFOverF(:,neuronNumbers);



%compute traceColoring
traceColoring=zeros(size(derivs));

if strcmp(threshType,'abs')
    for i=1:size(derivs,2)
        traceColoring(derivs(:,i)-posThresh(neuronNumbers(i))>0,i)=2;  %rise
        traceColoring(derivs(:,i)+abs(negThresh(neuronNumbers(i)))<0,i)=4;  %fall    
    end
else
    
    threshScalingPos=max(derivs,[],1);
    threshScalingNeg=min(derivs,[],1);
    for i=1:size(derivs,2)
        traceColoring(derivs(:,i)./threshScalingPos(i)-posThresh(neuronNumbers(i))>0,i)=2;  %rise
        traceColoring(derivs(:,i)./abs(threshScalingNeg(i))+abs(negThresh(neuronNumbers(i)))<0,i)=4;  %fall
    end   
    
end

%impute plateau and trough states
for n=1:size(traceColoring,2)
    
    if traceColoring(1,n)==0
           %find first non-zero state and work backwards
           firstNonZeroValue=traceColoring(find(traceColoring(:,n)>0,1,'first'),n);
           if isempty(firstNonZeroValue)
               firstNonZeroValue=1;
           end
           if (firstNonZeroValue==2 || firstNonZeroValue==1)
               traceColoring(1,n)=1;
           else
               traceColoring(1,n)=3;
           end
               
               
    end
    
    for t=2:size(traceColoring,1)
        
        if traceColoring(t,n)==0 
            
            if traceColoring(t-1,n)==2 || traceColoring(t-1,n)==3
               traceColoring(t,n)=3;
            else
                traceColoring(t,n)=1;
            end
                 
        end
        
    end
end


    
%prevent High Troughs and/or Low Plateaus
if options.noHighTroughsFlag || options.noLowPlateausFlag
    
    midpoints=mean(traces,1); %mean   %this is always zero since traces are zero-centered
    %(max(traces,[],1)+min(traces,[],1))/2;  %median
        
    for n=1:size(traceColoring,2)
    
        currentSegStart=1;
        currentSegLength=1;
        for t=2:size(traceColoring,1)

                %find contiguous segment
                               
                if traceColoring(t,n)==traceColoring(t-1,n)
                    currentSegLength=currentSegLength+1;
                else
                    currentSegEnd=t-1;
                    
                    %change segment if necessary
 
                    if options.noHighTroughsFlag

                        if traceColoring(t-1,n)==1 && mean(traces(currentSegStart:currentSegEnd,n)) > bufferMargin+midpoints(n)
                           traceColoring(currentSegStart:currentSegEnd,n)=3;
                        end

                    end
                    if options.noLowPlateausFlag

                        if traceColoring(t-1,n)==3 && mean(traces(currentSegStart:currentSegEnd,n)) < midpoints(n)-bufferMargin
                            traceColoring(currentSegStart:currentSegEnd,n)=1;
                        end

                    end                    
                    
                    
                    %reset segment tracker
                    currentSegLength=1;
                    currentSegStart=t;
 
                end
    

        end
    end
   
    
end
    
  
%convert fall-to-plateau prior states into plateaus
for n=1:size(traceColoring,2)

    if numel(noFallToPlateauFlag)==1 
        thisFlag=noFallToPlateauFlag;
    else
        thisFlag=noFallToPlateauFlag(neuronNumbers(n));
    end
        
    if thisFlag
     
        for t=2:size(traceColoring,1)

            if  traceColoring(t-1,n)==4 && traceColoring(t,n)==3

                thisT=t-1;
                while thisT>0 && traceColoring(thisT,n)==4  %work backward

                    traceColoring(thisT,n)=3;
                    thisT=thisT-1;

                end

            end
        end
    end

end


%add single-frame troughs to fall-to-rise transtions
if forceTroughsFlag
    for n=1:size(traceColoring,2)
        for t=2:size(traceColoring,1)
                if traceColoring(t-1,n)==4 && traceColoring(t,n)==2
                    traceColoring(t-1,n)=1;
                end
        end
    end
end
    
%add single-frame plateaus to rise-to-fall transtions
if forcePlateausFlag
    for n=1:size(traceColoring,2)
        for t=2:size(traceColoring,1)
                if traceColoring(t-1,n)==2 && traceColoring(t,n)==4
                    traceColoring(t-1,n)=3;
                end
        end
    end
end
    



%remove plateaus if forceNoPlateaus
for n=1:size(traceColoring,2)
    
    
    if numel(forceNoPlateausFlag)==1 
        thisFlag=forceNoPlateausFlag;
    else
        thisFlag=forceNoPlateausFlag(neuronNumbers(n));
    end
        
    
    if thisFlag
    
   
        for t=1:size(traceColoring,1)
            
            if traceColoring(t,n)==3
                if derivs(t,n)>0
                    traceColoring(t,n)=2;
                else
                    traceColoring(t,n)=4;
                end
            end
            
        end
        
    end
end

GenTransitionList(traceColoring);

%fix bad transition segments
   
for n=1:size(traceColoring,2)

    if numel(fixBadTransitionsFlag)==1 
        thisFlag=fixBadTransitionsFlag;
    else
        thisFlag=fixBadTransitionsFlag(neuronNumbers(n));
    end
            
    if thisFlag

        if ~isempty(transitionListCellArray{n,10})         
            for i=transitionListCellArray{n,10}

                %make a 1-4-1 sequence into a 1-1-1
                if i+GetRunLength(traceColoring(:,n),i)>size(traceColoring,1) || traceColoring(i+GetRunLength(traceColoring(:,n),i),n)==1
                        traceColoring(i:i+GetRunLength(traceColoring(:,n),i)-1,n)=1;
                end

            end
        end

    end

end   
GenTransitionList(traceColoring);


for n=1:size(traceColoring,2)
    
   if numel(fixBadTransitionsFlag)==1 
        thisFlag=fixBadTransitionsFlag;
   else
        thisFlag=fixBadTransitionsFlag(neuronNumbers(n));
   end
    
   if thisFlag

       if ~isempty(transitionListCellArray{n,8})
            for i=transitionListCellArray{n,8}

                %make a 3-2-4 or 3-2-3 or 3-2-4 sequence into a 3-3-3 or
                %3-3-4 provided [2] is small
%traces( i+GetRunLength(traceColoring(:,n),i),n) - traces(i,n)
                if i+GetRunLength(traceColoring(:,n),i)>size(traceColoring,1) || ...
                   (traceColoring(i+GetRunLength(traceColoring(:,n),i),n)>2 && traces( i+GetRunLength(traceColoring(:,n),i),n) - traces(i,n) < smallRiseCutoff)
                        traceColoring(i:i+GetRunLength(traceColoring(:,n),i)-1,n)=3;
                end

            end

       end
   end

end

GenTransitionList(traceColoring);







    function runLength=getPreRunLength(trace,time)
        %walk backward
        lastVal=trace(time);
        thisVal=trace(time);
        thisTime=time;
        runLength=1;
        while (thisVal==lastVal) && (thisTime>1)
            runLength=runLength+1;
            thisVal=trace(thisTime-1);
            thisTime=thisTime-1;
        end
    end

    function GenTransitionList(traceColoring)


        %generate transition list

        transitionListCellArray=cell(size(traceColoring,2),13);  %9 records all transitions
        transitionPreRunLengthArray=cell(size(traceColoring,2),13);  %9 records all transitions
        transitionRunLengthArray=cell(size(traceColoring,2),13);  %9 records all transitions


        for nn=1:size(traceColoring,2)
            for t=2:size(traceColoring,1)
                    thisTT=0;

                    if traceColoring(t-1,nn)==1 && traceColoring(t,nn)==2
                        thisTT=1;

                    elseif  traceColoring(t-1,nn)==2 && traceColoring(t,nn)==3
                        thisTT=2;

                    elseif  traceColoring(t-1,nn)==2 && traceColoring(t,nn)==4
                        thisTT=3;

                    elseif  traceColoring(t-1,nn)==3 && traceColoring(t,nn)==4
                        thisTT=4;

                    elseif  traceColoring(t-1,nn)==4 && traceColoring(t,nn)==1
                        thisTT=5;

                    elseif  traceColoring(t-1,nn)==4 && traceColoring(t,nn)==2
                        thisTT=6;

                    elseif  traceColoring(t-1,nn)==2 && traceColoring(t,nn)==1
                        thisTT=7;

                    elseif  traceColoring(t-1,nn)==3 && traceColoring(t,nn)==2
                        thisTT=8;

                    elseif  traceColoring(t-1,nn)==4 && traceColoring(t,nn)==3
                        thisTT=9;

                    elseif  traceColoring(t-1,nn)==1 && traceColoring(t,nn)==4
                        thisTT=10;

                    elseif  traceColoring(t-1,nn)==1 && traceColoring(t,nn)==3
                        thisTT=11;

                    elseif  traceColoring(t-1,nn)==3 && traceColoring(t,nn)==1
                        thisTT=12;

                    end

                    if thisTT
                        transitionListCellArray{nn,thisTT}=[transitionListCellArray{nn,thisTT} t];
                        transitionPreRunLengthArray{nn,thisTT}=[transitionPreRunLengthArray{nn,thisTT} getPreRunLength(traceColoring(:,nn),t-1)];
                        transitionRunLengthArray{nn,thisTT}=[transitionRunLengthArray{nn,thisTT} GetRunLength(traceColoring(:,nn),t)];

                        transitionListCellArray{nn,13}=[transitionListCellArray{nn,13} t];
                    end


            end
        end
    end


end