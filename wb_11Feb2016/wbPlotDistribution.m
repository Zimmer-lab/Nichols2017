function sA=wbPlotDistribution(wbstruct,evalType,options)

flagstr=[];
sA=[];

if nargin<1 || isempty(wbstruct)
    wbstruct={wbload([],false)};
end

if ~iscell(wbstruct)
    wbstruct={wbstruct};
end

if nargin<3
    options=[];
end

if ~isfield(options,'refDir')
    options.refDir=[];
end


if ~isfield(options,'refWbstruct')
    options.refWbstruct=[];
end

if ~isfield(options,'plotRef')
    options.plotRef=true;
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset=[];
end



if ~isfield(options,'computePValues')
    options.computePValues=true;
end

if ~isfield(options,'computePValuesNumSamples')
    options.computePValuesNumSamples=1000;
end

if numel(wbstruct)>1
    dataFolders=listfolders(pwd,true);
    nd=numel(dataFolders);
    flagstr=[flagstr '-multi'];
else
    nd=1;
end

if ~isempty(options.refWbstruct)
    ref.wbstruct=options.refWbstruct;
    ref.nd=numel(ref.wbstruct);
    
elseif options.refDir
    
    ref.wbstruct=wbload(options.refDir,false);
    ref.dataFolders=listfolders(options.refDir,true);
    ref.nd=numel(ref.dataFolders);
else
    ref.nd=1;
end

if ~isfield(options,'extraExclusionList')
    options.extraExclusionList=[];
    out_struct.exclusionList=[]; 
    
else
    
    for nn=1:length(options.extraExclusionList)   

        [~, ~, simpleNeuronsToExclude(nn)] = wbgettrace(options.extraExclusionList{nn},wbstruct{1});
    end
    out_struct.exclusionList=simpleNeuronsToExclude(~isnan(simpleNeuronsToExclude));

end




if nargin<2 || isempty(evalType)
    evalType='rms';   %rmsD
    sortMethod='rms';
else
    sortMethod=evalType;
end

if ischar(evalType) 
    evalType={evalType};  %convert a string input into 1-cell array
end


if ~isfield(options,'fieldName');
    options.fieldName={'derivs','traces'};    
%   options.fieldName='deltaFOverF_bc';
end

if ~isfield(options,'stimAnalysis');
    options.stimAnalysis=false;
end


if ~isfield(options,'collapseClassesFlag');
    options.collapseClassesFlag=false;
end

if ~isfield(options,'subplotFlag');
    options.subplotFlag=false;
end

if ~isfield(options,'showPoints');
    options.showPoints=false;
end


if ~isfield(options,'addIDsFlag');
    options.addIDsFlag=true;
end



if ~isfield(options,'extraMeasurements');  %extra quantifications
    options.extraMeasurements=[];
end



if ~isfield(options,'range');
    options.range=[];
else
    flagstr=[flagstr '-[' num2str(options.range(1))  '-' num2str(options.range(end)) ']' ];
end

if nargin<2 || ~isfield(options,'saveDir')

    options.saveDir=pwd;
        
end

if nargin<2 || ~isfield(options,'saveFlag')
    options.saveFlag=true;
end


%plot params
plotAvgValLineFlag=true;
IDLabelLineRelativeLength=.025;

%trace prescrub
for d=1:nd
    
    if ischar(options.fieldName)
        traces{d}=wbstruct{d}.simple.(options.fieldName);
    else %derivs
        traces{d}=wbstruct{d}.simple.(options.fieldName{1}).(options.fieldName{2});
        flagstr=[flagstr '-' options.fieldName{1}];
    end
    labels{d}=wbstruct{d}.simple.ID1;

end


if ~isempty(options.refWbstruct)
    for d=1:ref.nd

        if ischar(options.fieldName)
            ref.traces{d}=ref.wbstruct{d}.simple.(options.fieldName);
        else %derivs
            ref.traces{d}=ref.wbstruct{d}.simple.(options.fieldName{1}).(options.fieldName{2});
        end
        ref.labels{d}=ref.wbstruct{d}.simple.ID1;
    end
end



%WB specific: exclude neurons that are marked for exclusion
if isfield(out_struct,'exclusionList')

    fprintf('%s','excluding');
    for i=1:length(options.extraExclusionList)
        fprintf(' %s',options.extraExclusionList{i});
    end
    fprintf('.\n');

end
thisExclusionListLogical=false(1,size(traces{1},2));


% %WB specific: exclude neurons that aren't in neuronSubset
% 
if ~isempty(options.neuronSubset)
    [~, goodIndices]=wbGetTraces(wbstruct{1},true,[],options.neuronSubset);
    
   
    thisExclusionListLogical=true(1,size(traces{1},2));
    thisExclusionListLogical(goodIndices)=false;
end




thisExclusionListLogical(out_struct.exclusionList)=true;




%WB specific: drop low rms components
% if options.numComponentsToDrop>0
% 
%     tracesExcluded=traces(:,~thisExclusionListLogical);
%     pretraces0Excluded=pretraces0(:,~thisExclusionListLogical);
% 
%     tracesUnExcludedIndices=find(~thisExclusionListLogical);
%     sortOptions=[];
% 
%     if strcmp(options.dropCriterion,'rmsd') && options.derivFlag
%        [~,tracesExcludedSortIndex]=wbSortTraces(tracesExcluded,'rms',[],[],sortOptions);
%     else
%        [~,tracesExcludedSortIndex]=wbSortTraces(pretraces0Excluded,'rms',[],[],sortOptions);   
%     end
% 
%     numTracesExcluded=size(tracesExcluded,2);
% 
%     excludedIndicesToDrop= tracesExcludedSortIndex(numTracesExcluded-options.numComponentsToDrop+1:numTracesExcluded);
% 
%     indicesToDrop=tracesUnExcludedIndices(excludedIndicesToDrop);
% 
% 
%     thisExclusionListLogical(indicesToDrop)=true;
% 
% end


%remove excluded traces
traces{1}(:,thisExclusionListLogical)=[];
labels{1}(thisExclusionListLogical)=[];



options.yLabel=evalType;


for et=1:length(evalType)  %multiple eval methods
    
    for d=1:nd  %datasets
        
        
        
        sortOptions.range=options.range;
        [tracesSorted{d},sortIndex{d},sortVal{d}]=wbSortTraces(traces{d},sortMethod,[],[],sortOptions);
        [sortVal_sorted{d} sortVal_lookup{d}]=sort(sortVal{d},'descend'); 
        
        labelsSorted{d}=labels{d}(sortIndex{d});
                
    
        %stim 
        if strcmp(evalType,'rms')

            %compute stim rms

            if options.stimAnalysis

                sA.stimRange{d}=logical(wbgetstimcoloring(wbstruct{d}));
                sA.noStimRange{d}=~logical(wbgetstimcoloring(wbstruct{d}));
                sA.noStimRange{d}(1:find(wbgetstimcoloring(wbstruct{d}),1,'first'))=false;
                sA.preStimRange{d}=false(size(sA.stimRange));
                sA.preStimRange{d}(1:find(wbgetstimcoloring(wbstruct{d}),1,'first'))=true;


                sA.tracesStim{d}=traces{d}(sA.stimRange{d},:);
                sA.tracesNoStim{d}=traces{d}(sA.noStimRange{d},:);
                sA.tracesPreStim{d}=traces{d}(sA.preStimRange{d},:);

                sA.traces_zerocenter_stim{d}=detrend(sA.tracesStim{d},'constant');
                sA.traces_zerocenter_noStim{d}=detrend(sA.tracesNoStim{d},'constant');
                sA.traces_zerocenter_preStim{d}=detrend(sA.tracesPreStim{d},'constant');

                numTraces(d)=size(traces{d},2);
                
                for j=1:numTraces(d)
                    sA.sortValStim{d}(j)=rms(fixnan(sA.traces_zerocenter_stim{d}(:,j)));
                    sA.sortValNoStim{d}(j)=rms(fixnan(sA.traces_zerocenter_noStim{d}(:,j)));
                    sA.sortValPreStim{d}(j)=rms(fixnan(sA.traces_zerocenter_preStim{d}(:,j)));
                end 
                            
                
                
                sA.sortVal_sorted_Stim{d}=sA.sortValStim{d}(sortVal_lookup{d});
                sA.sortVal_sorted_noStim{d}=sA.sortValNoStim{d}(sortVal_lookup{d});
                sA.sortVal_sorted_preStim{d}=sA.sortValPreStim{d}(sortVal_lookup{d});    

            end      

        end



        
        totalVal(d)=sum(sortVal{d});
        avgVal(d)=totalVal(d)/length(sortVal{d});
        yRange(d)=max(sortVal_sorted{d})-min(sortVal_sorted{d});   
        yMax(d)=max(sortVal_sorted{d});
        yMin(d)=min(sortVal_sorted{d});      
    end %d
    yRangeAll=max(yMax)-min(yMin);  
   
    
    if ~isempty(options.refWbstruct)
        for d=1:ref.nd

            [ref.tracesSorted{d},ref.sortIndex{d},ref.sortVal{d}]=wbSortTraces(ref.traces{d},sortMethod,[],[],sortOptions);
            [ref.sortVal_sorted{d} ref.sortVal_lookup{d}]=sort(ref.sortVal{d},'descend');    
            ref.totalVal(d)=sum(ref.sortVal{d});
            ref.avgVal(d)=ref.totalVal(d)/length(ref.sortVal{d});
            ref.yRange(d)=max(ref.sortVal_sorted{d})-min(ref.sortVal_sorted{d});   
            ref.yMax(d)=max(ref.sortVal_sorted{d});
            ref.yMin(d)=min(ref.sortVal_sorted{d});

        end
        ref.yRangeAll=max(ref.yMax)-min(ref.yMin);    

    end
        


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %compile data across datasets
    
    if nd>1
        
        %initialize global neuron data struct
        [nIDs,nClasses]=LoadGlobalNeuronIDs;
        %globalMap=wbMakeGlobalMaps;

        for d=1:nd
            runInfo.dataSets{d}=wbMakeShortTrialname(wbstruct{d}.trialname);
        end

        
        if options.collapseClassesFlag
            
            nGlobalLabels=nClasses;            
        else            
            nGlobalLabels=nIDs;            
        end
        
        
        for i=1:length(nGlobalLabels)

           globalNeuronData(i).label=nGlobalLabels{i};
           globalNeuronData(i).values=[];
           globalNeuronData(i).trialNames=[];

        end

        for d=1:nd


            [theseIDs simpleNeuronNumber]=wbListIDs(wbstruct{d});

            for n=1:length(theseIDs)

                    ID=theseIDs{n};


                                       
                    if options.collapseClassesFlag
                        
                    
                        thisMasterNumber=find(strcmpi(nClasses,ID(1:end-1)));
                        if isempty(thisMasterNumber)
                            thisMasterNumber=find(strcmpi(nClasses,ID(1:end-2)));    
                        end
                        if isempty(thisMasterNumber)
                            thisMasterNumber=find(strcmpi(nClasses,ID));    
                        end
                        

                        if ~isempty(simpleNeuronNumber(n))
                            x=find(sortIndex{d}==simpleNeuronNumber(n));
                            thisValue=sortVal_sorted{d}(x);
                            globalNeuronData(thisMasterNumber).values=[globalNeuronData(thisMasterNumber).values thisValue];
                            globalNeuronData(thisMasterNumber).trialNames=[globalNeuronData(thisMasterNumber).trialNames {wbMakeShortTrialname(wbstruct{d}.trialname)}];

                        end


                    else
                        
                        thisMasterNumber=find(strcmpi(nIDs,ID));


                        if ~isempty(simpleNeuronNumber(n))
                            x=find(sortIndex{d}==simpleNeuronNumber(n));
                            thisValue=sortVal_sorted{d}(x);
                            globalNeuronData(thisMasterNumber).values=[globalNeuronData(thisMasterNumber).values thisValue];
                            globalNeuronData(thisMasterNumber).trialNames=[globalNeuronData(thisMasterNumber).trialNames {wbMakeShortTrialname(wbstruct{d}.trialname)}];

                        end

                        
                    end

            end

        end
        
        
        
        %average data and drop nulls
        values_mean=[];
        values_compiled=[];      
        k=0;           
        for n=1:numel(globalNeuronData)
            if ~isempty(globalNeuronData(n).values)
                k=k+1;
                values_compiled{k}=globalNeuronData(n).values;
                values_mean(k)=mean(globalNeuronData(n).values);
                label{k}=globalNeuronData(n).label;

            end
        end
        numValues=k;               
        [values_mean_sorted values_mean_sortIndex]=sort(values_mean,'descend');

        
        if ~isempty(options.refWbstruct)
            
                     
            for i=1:length(nGlobalLabels)
                ref.globalNeuronData(i).label=nGlobalLabels{i};
                ref.globalNeuronData(i).values=[];
                ref.globalNeuronData(i).trialNames=[];
            end
            

            for d=1:ref.nd


                [ref.theseIDs ref.simpleNeuronNumber]=wbListIDs(ref.wbstruct{d});

                for n=1:length(ref.theseIDs)

                        ID=ref.theseIDs{n};
   
                        if options.collapseClassesFlag


                            thisMasterNumber=find(strcmpi(nClasses,ID(1:end-1)));
                            if isempty(thisMasterNumber)
                                thisMasterNumber=find(strcmpi(nClasses,ID(1:end-2)));    
                            end
                            if isempty(thisMasterNumber)
                                thisMasterNumber=find(strcmpi(nClasses,ID));    
                            end
                        
                        else
                            
                            thisMasterNumber=find(strcmpi(nIDs,ID));
 
                        end
                        

                        if ~isempty(ref.simpleNeuronNumber(n))
                            x=find(ref.sortIndex{d}==ref.simpleNeuronNumber(n));
                            thisValue=ref.sortVal_sorted{d}(x);
                            ref.globalNeuronData(thisMasterNumber).values=[ref.globalNeuronData(thisMasterNumber).values thisValue];
                            ref.globalNeuronData(thisMasterNumber).trialNames=[ref.globalNeuronData(thisMasterNumber).trialNames {wbMakeShortTrialname(ref.wbstruct{d}.trialname)}];

                        end                        
                        
                end

            end
            
            
            %reference data: average data and drop nulls
            ref.values_mean=[];
            ref.values_compiled=[];
            k=0;
            
                
            for n=1:numel(ref.globalNeuronData)
                if ~isempty(ref.globalNeuronData(n).values)
                    k=k+1;
                    ref.values_compiled{k}=ref.globalNeuronData(n).values;
                    ref.values_mean(k)=mean(ref.globalNeuronData(n).values);
                    ref.label{k}=ref.globalNeuronData(n).label;

                end
            end

               
            [ref.values_mean_sorted ref.values_mean_sortIndex]=sort(ref.values_mean,'descend');
            ref.numValues=k;

            
            %created ref-sorted version of original data, only for
            %common neurons
                    
            k=0;
            for rl=1:numel(ref.values_mean_sorted)
          
                thisrefn=ref.values_mean_sortIndex(rl);
                thisn = find(strcmp(ref.label{thisrefn},label));


                if thisn
                    k=k+1;
                    refsorted.values_compiled{k}=values_compiled{thisn};
                    refsorted.values_mean(k)=values_mean(thisn);
                    refsorted.label{k}=label{thisn};
                    
                    refsorted.refvalues_compiled{k}=ref.values_compiled{thisrefn};
                    refsorted.refvalues_mean(k)=ref.values_mean(thisrefn);
                    
                end

            end
            refsorted.numValues=k;
            

        end
        

        
    end
    
    
    %pValue generation
    if options.computePValues && ~isempty(options.refWbstruct)
        
        for i=1:refsorted.numValues
            
            SToptions.numSamples=options.computePValuesNumSamples;
            SToptions.testStatisticFunction=@mean;
            
            testType='permutation';
            
            D.empDist=[refsorted.values_compiled{i},refsorted.refvalues_compiled{i}];
            D.acceptLevel=refsorted.values_mean(i);
            D.sampleSize=length(refsorted.values_compiled{i});
            pValue(i)=SigTest(testType,D,SToptions);
            pValue(i)=max([pValue(i)  1/SToptions.numSamples]);
            nValue(i)=D.sampleSize;
            
        end
        
        
    end
    
    

    
    
    %%%%%%%PLOTTING
    
    if nd==1
       
        %plot for one dataset
        
        
        %setup fig
        figure('Position',[200 200 1200 600]);
        subplot(2,2,1:2);


        d=1;
        hold on;

        sA.labelsSorted{d}=labelsSorted{d};
            
        if options.stimAnalysis
            
            
            handles.plotA=plot(1:length(sortVal{d}),sA.sortVal_sorted_preStim{d});
            set(handles.plotA,'Color',[0.5 0.5 0.5]);

            handles.plotB=plot(1:length(sortVal{d}),sA.sortVal_sorted_Stim{d});
            set(handles.plotB,'Color','b');
            
            handles.plotC=plot(1:length(sortVal{d}),sA.sortVal_sorted_noStim{d});
            set(handles.plotC,'Color','r');
 
            legend({'prestim','stim','nostim'});


        else
            
            [handles.axes,handles.plot1,handles.plot2] = plotyy(1:length(sortVal{d}),sortVal_sorted{d},1:length(sortVal{d}),cumsum(sortVal_sorted{d}/totalVal));
            set(handles.plot1,'Color',color(1,length(sortMethod)),'Marker','.','MarkerSize',12);

            sA.sortVal_sorted{d}=sortVal_sorted{d};

            
            set(handles.axes(1),'YLim',[0 1.1*max(sortVal{d})]);
            set(handles.axes(2),'YLim',[0 1.1]);  
            set(get(handles.axes(1),'Ylabel'),'String',options.yLabel) ;
            set(get(handles.axes(2),'Ylabel'),'String','cumulative') 
            set(handles.axes(1),'YTick',[0:0.1:1.1*max(sortVal{d})]);
            set(handles.axes(2),'YTick',[0:0.1:1.0]);

            set(handles.axes,'XTick',[0:10:length(sortVal{d})]);
            set(handles.axes,'XLim',[0 length(sortVal{d})]);
        
            legend(strrep(sortMethod,'_','\_'));

        end

        box off;
        if plotAvgValLineFlag
            hline(avgVal,[0.5 0.5 0.5]);
            text( length(sortVal{d})-2,avgVal,'avg','HorizontalAlignment','right','VerticalAlignment','bottom','Color',[0.5 0.5 0.5]);
        end

        xlabel('neuron');
        ylabel(options.yLabel);

        if options.addIDsFlag

            if ~isempty(options.neuronSubset)
                ID=labelsSorted{d};
                for j=1:length(ID)

                    
                    x=j;
                    y=sortVal_sorted{d}(x);
                    text(x,y+yRange*IDLabelLineRelativeLength,ID{j},'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',90,'FontSize',8);
                    line([x x],[y y+yRange*IDLabelLineRelativeLength],'Color','k');
                    
                end                
                
                

            else

                [ID simpleNeuronNumber]=wbListIDs(wbstruct{d});            
                for j=1:length(ID)

                    if ~isempty(simpleNeuronNumber(j))
                        x=find(sortIndex{d}==simpleNeuronNumber(j));
                        y=sortVal_sorted{d}(x);
                        text(x,y+yRange*IDLabelLineRelativeLength,ID{j},'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',90,'FontSize',8);
                        line([x x],[y y+yRange*IDLabelLineRelativeLength],'Color','k');
                    end
                end

            end
        

        end
        
        

        subplot(2,2,3);
        
        if options.stimAnalysis
            
            
            edges=0:0.0025:.08;
            hist_prestim=histc(sA.sortVal_sorted_preStim{d},edges);
            [x,y]=Stepify(edges+.00125,hist_prestim);
            
            plot(x,y,'Color',[0.5 0.5 0.5]);          
       

            hold on;
            
            hist_stim=histc(sA.sortVal_sorted_Stim{d},edges);
            [x,y]=Stepify(edges+.00125,hist_stim);
            plot(x,y,'b');   
            
            hist_nostim=histc(sA.sortVal_sorted_noStim{d},edges);
            [x,y]=Stepify(edges+.00125,hist_nostim);
            plot(x,y,'r');   
            
            
            vline(mean(sA.sortVal_sorted_preStim{d}),[0.5 0.5 0.5]);
            vline(mean(sA.sortVal_sorted_Stim{d}),'b');
            vline(mean(sA.sortVal_sorted_noStim{d}),'r');
            
        else
            
            hist(sortVal{d},20);
            
        end
        
        ylabel('# of neurons');
        xlabel(options.yLabel);
        xlim([0 max(sortVal{d})+1/20]);
        box off;

        
        
        
        subplot(2,2,4);
        
        if options.stimAnalysis

            cc.stim=corrcoef(sA.tracesStim{d});
            cc.nostim=corrcoef(sA.tracesNoStim{d});
            cc.prestim=corrcoef(sA.tracesPreStim{d});

            cc.stim(cc.stim==1)=0;
            cc.nostim(cc.nostim==1)=0;
            cc.prestim(cc.prestim==1)=0;

            edges=-1:0.02:1;

            hist_cc_prestim=histc(cc.prestim(:),edges);
            hist_cc_stim=histc(cc.stim(:),edges);
            hist_cc_nostim=histc(cc.nostim(:),edges);

            plot(edges+.01,hist_cc_prestim,'Color',[0.5 0.5 0.5]);
            hold on;
            plot(edges+.01,hist_cc_stim,'Color','b');
            plot(edges+.01,hist_cc_nostim,'Color','r');

            vline(mean(abs(cc.prestim(:))),[0.5 0.5 0.5]);
            vline(mean(abs(cc.stim(:))),'b');
            vline(mean(abs(cc.nostim(:))),'r');
            ylabel('# of pairs');
            xlabel('corr. coeff');
        
        else
        
    
            [x,bin]=hist(sortVal{d},20);
            bar(log(bin),x);
            ylabel('# of neurons');
            xlabel(['log ' options.yLabel]);
            box off;
            
        
            sA.logplot_bins=bin;
            sA.logplot_counts=x;
            
        end
        
        
       % xlim([min(log(bin)) max(log(bin))]);
        box off;

        mtit([evalType{et} ' - ' wbstruct{d}.displayname '  ' flagstr]);
        
        if options.saveFlag
            export_fig([options.saveDir '/DistributionPlot-' evalType{et}  '-' wbMakeShortTrialname(wbstruct{d}.trialname) flagstr '.pdf'],'-transparent'); 
        end

    else  %multi datasets, just plot labeled neurons
        
        
        
        if ~options.subplotFlag
            figure('Position',[200 200 1200 600]);
        end
        
        
        if isempty(options.refDir)
        
            plot(values_mean_sorted);

            %base('vms',values_mean_sorted);


            xlabel('neuron');
            ylabel(options.yLabel);

            if options.addIDsFlag

                for x=1:length(label)
                        y=values_mean_sorted(x);

                        text(x,y+yRangeAll*IDLabelLineRelativeLength,label{values_mean_sortIndex(x)},'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',90,'FontSize',8);
                        line([x x],[y y+yRangeAll*IDLabelLineRelativeLength],'Color','k');
                end

            end
        
        else  %refDir exists
            
            
            if options.plotRef
                
                hold on;
                
                %plot(refsorted.refvalues_mean,'b');

                for i=1:refsorted.numValues
                    
                    %line([i i],[refsorted.refvalues_mean(i) refsorted.values_mean(i)],'Color','r');
                    if (refsorted.values_mean(i) < refsorted.refvalues_mean(i) )
                        thisColor='b';
                    else
                        thisColor=color('lb');
                    end
                    
                    
                            if pValue(i)<.04
                                thisColor='r';

                            end
                            
                    if  refsorted.refvalues_mean(i) - refsorted.values_mean(i) > .0005
                        
                        baseValue=min([refsorted.values_mean(i) refsorted.refvalues_mean(i)])+.0005;
                        rectangle('Position',[i baseValue  0.9 abs(refsorted.refvalues_mean(i)-refsorted.values_mean(i))-.0005],...
                            'FaceColor',thisColor,'EdgeColor','none');     
                        patch([i  i+.9 i+.45],...
                            [baseValue baseValue baseValue-.0005],thisColor,'EdgeColor','none');
                                        
                    elseif refsorted.refvalues_mean(i) - refsorted.values_mean(i) < -.0005
                        
                        baseValue=min([refsorted.values_mean(i) refsorted.refvalues_mean(i)]);
                        topValue=max([refsorted.values_mean(i) refsorted.refvalues_mean(i)]);
                        rectangle('Position',[i baseValue  0.9 abs(refsorted.refvalues_mean(i)-refsorted.values_mean(i))-.0005],...
                            'FaceColor',thisColor,'EdgeColor','none');     
                        patch([i  i+.9 i+.45],...
                            [topValue-.0005 topValue-.0005 topValue],thisColor,'EdgeColor','none');
                                                         
                        
                        
                    elseif  refsorted.refvalues_mean(i) - refsorted.values_mean(i) < .0005
                        
                        baseValue=min([refsorted.values_mean(i) refsorted.refvalues_mean(i)])+refsorted.refvalues_mean(i) - refsorted.values_mean(i);

                        patch([i i+.9 i+.45],...
                          [baseValue baseValue baseValue- (refsorted.refvalues_mean(i) - refsorted.values_mean(i))],thisColor,'EdgeColor','none');
                      
                    else
                        
                        height=abs(refsorted.refvalues_mean(i) - refsorted.values_mean(i));
                        topValue=max([refsorted.values_mean(i) refsorted.refvalues_mean(i)])+height;

                        patch([i i+.9 i+.45],...
                          [topValue-height topValue-height topValue],thisColor,'EdgeColor','none');
                        
                        
                        
                        
                    end
                    
                end

                if options.showPoints
                    
                    for i=1:refsorted.numValues
                        
                        plot(i*ones(size(refsorted.refvalues_compiled{i})), refsorted.refvalues_compiled{i},'LineStyle','.','Color','b','MarkerSize',10);
                        
                    end
                    
                end
                
                options.showPValues=false;

                if options.addIDsFlag

                    for x=1:refsorted.numValues
                            y=refsorted.refvalues_mean(x);
                            if pValue(x)<.04
                                thisColor='k';
                            else
                                thisColor=[0.5 0.5 0.5];
                            end
                            
                            
                            if (refsorted.values_mean(x) > refsorted.refvalues_mean(x))
                                thisHAlign='right';
                            else
                                thisHAlign='left';

                            end
                            
                            options.showPStars=true;
                            if options.showPStars
                                
                               if pValue(x)<.00001
                                    pStars='*****';
                               elseif pValue(x)<.0001
                                    pStars='****';
                               elseif pValue(x)<.001
                                    pStars='***';
                               elseif pValue(x)<.01
                                    pStars='**';    
                               elseif pValue(x)<.04  
                                    pStars='*'; 
                               else
                                    pStars='';
                                    
                               end
                                    
                            else
                                
                                pStars='';
                                
                            end
                            
                            if options.showPValues
                                 text(x+0.5,y,[refsorted.label{x}  ' n=' num2str(nValue(x)) ' p<' num2str(pValue(x),2)],...
                                   'HorizontalAlignment',thisHAlign,'VerticalAlignment','middle','Rotation',90,'FontSize',9,'Color',thisColor);
                            else
                                text(x+0.5,y,[' ' refsorted.label{x} ' ' pStars] ,...
                                   'HorizontalAlignment',thisHAlign,'VerticalAlignment','middle','Rotation',90,'FontSize',9,'Color',thisColor);
                            end
                            
                           % line([x x],[y y+yRangeAll*IDLabelLineRelativeLength],'Color','k');
                    end

                end
                
                xlabel('neuron');
                ylabel(options.yLabel);                
                
              
            else
            
            
                plot(refsorted.values_mean);



                xlabel('neuron');
                ylabel(options.yLabel);

                if options.addIDsFlag

                    for x=1:length(refsorted.label)
                            y=refsorted.values_mean(x);

                            text(x,y+yRangeAll*IDLabelLineRelativeLength,refsorted.label{x},'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',90,'FontSize',9);
                            line([x x],[y y+yRangeAll*IDLabelLineRelativeLength],'Color','k');
                    end

                end
            
            
            
            end

            
             if isempty(options.extraMeasurements) 
                 xlim([0 length(refsorted.label)+1]); 
             end
            
            
            
            
            
        end
    
    end
    
    if ~isempty(options.extraMeasurements)
        

        theseValues_compiled=[];
        theseRefValues_compiled=[];
        
        for i=1:length(options.extraMeasurements.classes)
            
            thisN=find(strcmp(refsorted.label,options.extraMeasurements.classes{i}));
            theseRefValues_compiled=  [theseRefValues_compiled refsorted.refvalues_compiled{thisN}];
            theseValues_compiled=  [theseValues_compiled refsorted.values_compiled{thisN}];           
      
        end
        
        theseRefValues_mean=mean(theseRefValues_compiled);
        theseValues_mean=mean(theseValues_compiled);            
            
%         line([refsorted.numValues+1.95  refsorted.numValues+2.05],[theseRefValues_mean theseRefValues_mean],'Color','b');
%         line([refsorted.numValues+2  refsorted.numValues+2],[theseRefValues_mean theseValues_mean],'Color','r');
        %pValue generation
        thisColor=[0.5 0.5 0.5];

        if options.computePValues && ~isempty(options.refWbstruct)
                SToptions.numSamples=options.computePValuesNumSamples;
                SToptions.testStatisticFunction=@mean;
                testType='permutation';
                D.empDist=[theseRefValues_compiled,theseValues_compiled];
                D.acceptLevel=theseValues_mean;
                D.sampleSize=length(theseValues_compiled);
                thisPValue=SigTest(testType,D,SToptions);
                thisPValue=max([thisPValue  1/SToptions.numSamples]);
                

        end
        

         if (refsorted.values_mean(i) < refsorted.refvalues_mean(i) )
            thisColor='b';
         else
            thisColor=color('lb');
         end
         
                if thisPValue<.05
                    thisColor='r';
                end        
         
         baseValue=min([theseRefValues_mean theseValues_mean])+.0005;
         rectangle('Position',[refsorted.numValues+2 baseValue 0.9 abs(theseRefValues_mean-theseValues_mean)-.0005],...
            'FaceColor',thisColor,'EdgeColor','none');

        
         patch([refsorted.numValues+2  refsorted.numValues+2.9 refsorted.numValues+2.45],...
             [baseValue baseValue baseValue-.0005],thisColor,'EdgeColor','none');

        
        xlim([0 refsorted.numValues+3]);
        if options.showPValues
            text(refsorted.numValues+2+.5,theseRefValues_mean,[options.extraMeasurements.label ' n=' num2str(length(theseValues_compiled),2) ' p<' num2str(thisPValue,2)] ,...
            'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',90,'FontSize',9,'Color','k');
        else
            text(refsorted.numValues+2+.5,theseRefValues_mean,[' ' options.extraMeasurements.label] ,...
            'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',90,'FontSize',9,'Color','k');            
        end
         

     
         
         
         
         
    end
    
    
    

    export_fig([options.saveDir '/DistributionPlot-' evalType{et} flagstr '.pdf'],'-transparent','-painters'); 
 
    
end % number of evaltypes







end