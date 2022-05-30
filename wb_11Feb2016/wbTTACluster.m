function [outStruct,thisFigureHandle]=wbTTACluster(TTAStructFileName,options)
%wbTTACluster(TTAStructFileName,options)
%cluster TTA data
%
%
%for multi-trial data, one neuronSubset will be used across all datasets
%

%% prelims 
flagstr=[];

if nargin<2
    options=[];
end

if ~isfield(options,'useHints')
    options.useHints=true;
end

if ~isfield(options,'multiTrialFlag')
    options.multiTrialFlag=false;
end 

if ~isfield(options,'multiTrialDir')
    options.multiTrialDir=pwd;
end

if options.multiTrialFlag
    folderList=listfolders(options.multiTrialDir,true);   %this is a multi-dataset parent folder
end

if ~isfield(options,'interactiveMode')
    options.interactiveMode=false;
end

if ~isfield(options,'saveDirectory')
    if exist('Quant','dir')
        options.saveDirectory=[pwd filesep 'Quant'];
    else
        options.saveDirectory=pwd;
    end
end

if ~isfield(options,'showUnclusteredMatrix')
    options.showUnclusteredMatrix=false;
end

if ~isfield(options,'saveFlag')
    if  options.interactiveMode
        options.saveFlag=false;
    else
        options.saveFlag=true;
    end
end

if ~isfield(options,'originatingFigureHandle')
    options.originatingFigureHandle=[];
end

if ~isfield(options,'existingFigureHandle')
    options.existingFigureHandle=[];
end

if isempty(options.existingFigureHandle)
    firstLaunchFlag=true;
else
    firstLaunchFlag=false;
end

if ~isfield(options,'transitionTypes')
    options.transitionTypes='SignedAllRises';
end

if nargin<1 || isempty(TTAStructFileName)
    
    
    if strcmpi(options.transitionTypes,'SignedAllFalls') && exist([pwd filesep 'Quant' filesep 'wbTTAFallStruct.mat'],'file')  && options.multiTrialFlag==false
        
        TTAStructFileName=[pwd filesep 'Quant' filesep 'wbTTAFallStruct.mat'];
        TTAStruct{1}=load(TTAStructFileName); 
        disp('wbTTACluster> wbTTAFallStruct.mat loaded.');
        
    elseif strcmpi(options.transitionTypes,'SignedAllRises') && exist([pwd filesep 'Quant' filesep 'wbTTARiseStruct.mat'],'file') && options.multiTrialFlag==false
    
        TTAStructFileName=[pwd filesep 'Quant' filesep 'wbTTARiseStruct.mat'];
        TTAStruct{1}=load(TTAStructFileName); 
        disp('wbTTACluster> wbTTARiseStruct.mat loaded.');
        
    else  %multiStruct
        
        disp('wbTTACluster> multistruct.');
        options.multiTrialDir
        folders=listfolders(options.multiTrialDir,true)
        for d=1:numel(folders)
            
            if strcmpi(options.transitionTypes,'SignedAllFalls')
                
                TTAStructFileName=[folders{d} filesep 'Quant' filesep 'wbTTAFallStruct.mat'];
                TTAStruct{d}=load(TTAStructFileName);
        
            else
                
                TTAStructFileName=[folders{d} filesep 'Quant' filesep 'wbTTARiseStruct.mat'];
                TTAStruct{d}=load(TTAStructFileName);                
                
                
            end
            
        end

        if ~isfield(options,'neuronSubset')
            options.neuronSubset=wbListIDsInCommon(folders,'intersection');
        end
        
    end
            
else
    
   TTAStruct{1}=load(TTAStructFileName); 
    
end

%SET multiTrialFlag
if numel(TTAStruct)>1
    multiTrialFlag=true;
    flagstr=[flagstr '-multitrial'];
else
    multiTrialFlag=false;
end


if ~isfield(options,'wbDir');
    

    if exist([pwd filesep 'Quant'],'dir') && options.multiTrialFlag==false %this is a single dataset folder
        
        options.wbDir=pwd;
        
    else
        
        options.wbDir=folderList{1};
        disp(['wbTTACluster> Using ' folderList{1} ' as reference wb folder']);
        
    end
           
end


if ~isfield(options,'refWBstruct')
    
    refWBstruct=wbload(options.wbDir,false);
    if isempty(refWBstruct) 
        refWBstruct=wbload([],false);
    end
else
    refWBstruct=options.refWBstruct;   
end


if ~isfield(options,'neuronSubset')
    
    options.neuronSubset=wbListIDs(refWBstruct);   %will already be loaded if multi
end



if ~isfield(options,'activeNeuronFlags');
    options.activeNeuronFlags=[];
end

if ~isfield(options,'inPhaseNeuronFlags')
    options.inPhaseNeuronFlags=[];
end


if ~isfield(options,'useGlobalSigns')
    options.useGlobalSigns=true;
end


if options.useGlobalSigns
    globalMaps=wbMakeGlobalMaps;
end


if ~isfield(options,'neuronExclusions')
    options.neuronExclusions={};
end

if ~isfield(options,'refNeuron') || isempty(options.refNeuron)
    options.refNeuron={'AVAL'};    %default if no refNeuron in hints
    if options.useHints 
        
        if multiTrialFlag

            for d=1:numel(folderList)
                
                if exist([folderList{d} filesep 'Quant' filesep 'wbhints.mat'],'file')

                    hints{d}=load([folderList{d} filesep 'Quant' filesep 'wbhints.mat']);
                    if isfield(hints{d},'stateRefNeuron') && ~isempty(hints{d}.stateRefNeuron)
                        options.refNeuron{d}=hints{d}.stateRefNeuron;
                        disp(['wbTTACluster> using wbhints.mat file:  state reference neuron=' options.refNeuron{d}]);
                    end        

                end

            end

        else

            if exist(['Quant' filesep 'wbhints.mat'],'file')

                hints=wbHints; %load wbhints.mat
                if isfield(hints,'stateRefNeuron') && ~isempty(hints.stateRefNeuron)
                    options.refNeuron={hints.stateRefNeuron};
                    disp(['wbTTACluster> using wbhints.mat file:  state reference neuron=' options.refNeuron]);
                end        

            end

        end
        
    end
      
elseif ischar(options.refNeuron)
    options.refNeuron={options.refNeuron};
end

if ~isfield(options,'plotFlag')
    options.plotFlag=false;
end

if ~isfield(options,'subPlotFlag')
    options.subPlotFlag=false;
end


if ~isfield(options,'rotatePlot')
    options.rotatePlot=false;
end

if ~isfield(options,'savePDFFlag')
    options.savePDFFlag=true;
end


%cluster algo params
if ~isfield(options,'distanceMeasure')
    options.distanceMeasure='cityblock';
end

if ~isfield(options,'quantization')
    options.quantization='none';
end

if ~isfield(options,'maxClusters')
    options.maxClusters=2; %20;
end

if ~isfield(options,'clusterAlgorithm')
    options.clusterAlgorithm='kmeans';
end

if ~isfield(options,'clusterParam1')
    options.clusterParam1='maxclust';
end

if ~isfield(options,'preRunLengthCutoff');
    options.preRunLengthCutoff=10;
end

%%globals
 valuesBinary=[];
 valuesSign=[];
 inputValues=[];
 valuesForPlotting=[];
 numClusters=[];
 valuesSupplement=[];
 datasetMembership=[];
 
handles=[];
algorithmStringList={'kmeans','kmeansTwoStage','hierarchical','preRunLength'};
maxClusterStringList={'1','2','3','4','5','6','7','8'};
distanceMeasureStringList={'cityblock','sqeuclidean','cosine'};
quantizationStringList={'none','binary','trinary','precluster'};
        
OOBRvalStartingVal=10;
distanceMeasureStartingValue=1;
quantizationStartingValue=1;

quantization=quantizationStartingValue;
cutoffTime1=7;
cutoffTime2=7;
OOBRval=OOBRvalStartingVal;


if firstLaunchFlag
 
        
    if options.interactiveMode

        DrawGUI;

    end


    
    %remove excluded neurons from clustering input
    for i=1:length(options.neuronExclusions)
         options.neuronSubset(find(strcmpi(options.neuronSubset,options.neuronExclusions{i})))=[];
    end
    
    %% compile input data points in values (dxn)

    GetInputData;

    %% compute clustering and save

    DoClustering;
    if options.saveFlag
        SaveClustering; 
    end

else
    
    outStruct=[];
    thisFigureHandle=options.existingFigureHandle;
end

   

%% plots
 if options.plotFlag && ~options.interactiveMode
     %NEED TO REMOVE dependencies on .compiled
     
        if ~options.subPlotFlag
            figure('Position',[0 0 1200 800]);
        end
     
        cLim=[-7 7];
        cMap=jet; %bipolar(201,0.9);
        
        if options.showUnclusteredMatrix
            
            subtightplot(2,1,1,[0.1 .05],[.1 .1],[.05 .02]);

            RenderMatrix(values(meanSortIndex,:),cLim,casedLabels(meanSortIndex),cMap);
     %       set(gca,'XTick',1:length(TTAStruct.compiled.datasetNumber{1}));
     %       set(gca,'XTickLabel',TTAStruct.compiled.datasetNumber{1});
     %       trialNames= [ char([TTAStruct.runInfo.dataSets(:)]')' ;repmat('  ',length(TTAStruct.runInfo.dataSets),1)' ];

    %        title(['unclustered: ' trialNames(:)' ]);
            xlabel('dataset');
        
            subtightplot(2,1,2,[0.1 .05],[.1 .1],[.05 .02]);

        else
            subtightplot(2,1,2,[0.1 .05],[.1 .1],[.05 .02]);
        end
        
        
        RenderMatrix(values(meanSortIndex,sortIndex),cLim,casedLabels(meanSortIndex),cMap);
  %      set(gca,'XTick',1:length(TTAStruct.compiled.datasetNumber{1}));
        
        
        
        %dataset and transition number
%         for i=1:length(sortIndex)
%             
%             xTL{i}= [ num2str(TTAStruct.compiled.datasetNumber{1}(sortIndex(i))) ',' num2str(TTAStruct.compiled.transitionNumbers{1}(sortIndex(i)))  ];
%         end
            
        %ylabel([num2str(dataSet(rr)) '#' num2str(transitionList(rr)) ' -> C' num2str(clusterLabels(rr))]);

        
%         set(gca,'XTickLabel',xTL);
%         rotateXLabelsImage(gca,90);

%        title(['clustered measure: ' options.distanceMeasure ]);
%        xlabel('dataset');

        RenderMatrixColorbar('Middle','Left','Horizontal',cLim(1):cLim(2),cMap);
        xlabel('time (s)');

        axes('Position',[.05 .04 .93 .02]);
        RenderMatrix(outStruct.clusterMembership(sortIndex)');
        set(gca,'XTick',1:length(outStruct.clusterMembership'));
        set(gca,'XTickLabel',outStruct.clusterMembership(sortIndex)');
        xlabel(['clusters (max' options.maxClusters  ' )']);
        
        if options.rotatePlot
            view([90 90]);
        end
        
        if options.savePDFFlag
            export_fig(['TTACluster-' options.transitionTypes '.pdf']);
        end
        
        %%compile heatmaps
%         HPTTAoptions.clusterLabels=outStruct.clusterMembership';
%         HPTTAoptions.sorting=sortIndex;
%         HPTTAoptions.neuronSubset=casedLabels(meanSortIndex);
%         HPTTAoptions.neuronSigns=options.neuronSigns;
%         wbHeatPlotTTA(options.refNeuron,listfolders(pwd),HPTTAoptions);

 end

 %END MAIN
 
%% subfunctions
 
    function GetInputData

            [casedLabelsAll options.neuronSigns]=wbSetLabelCaseByNeuronSign(options.neuronSubset,double(options.inPhaseNeuronFlags)-0.5,refWBstruct,[],options);
               
            if isempty(options.activeNeuronFlags)       
                options.activeNeuronFlags=true(length(options.neuronSubset),1);
            end

            if isempty(options.inPhaseNeuronFlags)
                options.inPhaseNeuronFlags=options.neuronSigns>0;
            end

        
            if sum(options.activeNeuronFlags)>0
                 values=[];
                 valuesSupplement=[];
                 datasetMembership=[];

                 for d=1:numel(TTAStruct)
                     
                        neuronLabel1=options.refNeuron{d};
                        
                        n1=find(strcmpi(TTAStruct{d}.neuronLabels,neuronLabel1));
n1
                        neuronLabel2=options.neuronSubset(options.activeNeuronFlags);


                        valuesSubMat=zeros(length(neuronLabel2), length( TTAStruct{d}.delayDistributionMatrix{1,n1}  ));
                        
                        
                        for kk=1:length(neuronLabel2)

                            n2=find(strcmpi(TTAStruct{d}.neuronLabels,neuronLabel2{kk}));
                            
                            
%                             neuronLabel2{kk}
%  size(TTAStruct{d}.delayDistributionMatrix)                           
%                             n2
%                             n1
%                             neuronLabel1
                            
                            if isempty(n2)
                                if isfield(hints{d},neuronLabel2{kk})
                                    n2=find(strcmpi(TTAStruct{d}.neuronLabels,hints{d}.(neuronLabel2{kk})));
                                end
                            end
                            
                            if isempty(n2)
                                 n2=find(strncmpi(TTAStruct{d}.neuronLabels,neuronLabel2{kk},length(neuronLabel2{kk})),1);
                            end


                            if options.inPhaseNeuronFlags(n2)==(TTAStruct{d}.neuronSigns(n2)>0)...                                   
                                
                                valuesSubMat(kk,:)=InBounds(TTAStruct{d}.delayDistributionMatrix{n2,n1}/TTAStruct{d}.fps,-cutoffTime1,cutoffTime2,true);  %write nans for out of bounds times
                            else
                                valuesSubMat(kk,:)=InBounds(TTAStruct{d}.delayDistributionMatrixNEG{n2,n1}/TTAStruct{d}.fps,-cutoffTime1,cutoffTime2,true);  %write nans for out of bounds times

                            end
                        end
                        
                        values=[values, valuesSubMat];
  
                        valuesSupplement=[valuesSupplement, TTAStruct{d}.refNeuronPreRunLengths{n1}];
                        
                        datasetMembership=[datasetMembership, d*ones(1,length(TTAStruct{d}.refNeuronPreRunLengths{n1}))];
            
                 end
                 
disp('wbTTACluster>  prerunlengths:')
valuesSupplement
base('prl',valuesSupplement)

                valuesBinary=zeros(size(values));
                valuesBinary(isnan(values))=1;

                valuesSign=sign(values);
                valuesSign(isnan(values))=0;

                if quantization==1  %none

                   inputValues=values;
                   inputValues(isnan(values))=OOBRval;

                elseif quantization==2  %binary

                   inputValues=valuesBinary;

                elseif  quantization==3  %trinary

                   inputValues=valuesSign;

                elseif quantization==4  %pre-cluster neurons
                    maxRange=[cutoffTime1 cutoffTime2];
                    minSpread=5;

                    inputValues=AssignToCluster1D(values,minSpread,maxRange);

                end

                if quantization==1
                    valuesForPlotting=values;
                else
                    valuesForPlotting=inputValues;
                end

                means=nanmean(inputValues,2);
                [meansSorted,meanSortIndex]=sort(means);

                casedLabels=casedLabelsAll(options.activeNeuronFlags);

            
            end
        
        
        outStruct.inputValues=inputValues;
        outStruct.inputValuesSupp=valuesSupplement;
        outStruct.inputLabels=casedLabels;
        outStruct.inputActiveNeurons=options.activeNeuronFlags;
        outStruct.datasetMembership=datasetMembership;
        
    end

    function DrawGUI
        
        OrigFigurePosition=get(options.originatingFigureHandle,'Position');
        if isempty(OrigFigurePosition)
            OrigFigurePosition=[0 0 0 0];
        end
        
        
        if strcmp(options.transitionTypes,'SignedAllFalls')
            ttStr='Falls';
        else
            ttStr='Rises';
        end
        
        if ~isempty(options.existingFigureHandle)
            figure(options.existingFigureHandle);
            handles.mainFig=options.existingFigureHandle;
        else
            handles.mainFig=figure('Position',[OrigFigurePosition(1)+800 OrigFigurePosition(2) 800 800],'Name',[ttStr ' Clustering Panel']);
        end
        thisFigureHandle=handles.mainFig;

       
        handles.ttText=uicontrol('Style','text','Units','normalized','Position',[.8 .98 .1 .02],'String',upper(ttStr));

        
        handles.algorithmText=uicontrol('Style','text','Units','normalized','Position',[.01 .98 .1 .02],'String','algorithm');
        handles.algorithmPopup=uicontrol('Style','Popup','Units','normalized','Position',[.01 .955 .1 .02],'String',algorithmStringList,'Value',find(strcmpi(algorithmStringList,options.clusterAlgorithm)),'Callback',@(s,e) AlgorithmPopup);
        
        handles.maxClustersText=uicontrol('Style','text','Units','normalized','Position',[.11 .98 .1 .02],'String','max. clusters');
        handles.maxClusters=uicontrol('Style','Popup','Units','normalized','Position',[.11 .955 .1 .02],'String',maxClusterStringList,'Value',options.maxClusters,'Callback',@(s,e) MaxClustersPopup);
      
        handles.preRunLengthCutoffText=uicontrol('Style','text','Units','normalized','Position',[.11 .88+.05 .1 .02],'String','p.r.l. cutoff','Visible','off');
        handles.preRunLengthCutoffEditbox=uicontrol('Style','edit','Units','normalized','Position',[.11 .855+.05 .1 .03],'String',num2str(options.preRunLengthCutoff),'Callback',@(s,e) PreRunLengthCutoffCallback,'Visible','off');
                               
        handles.distanceMeasure=uicontrol('Style','Popup','Units','normalized','Position',[.20 .955 .11 .02],'String',distanceMeasureStringList,'Value',distanceMeasureStartingValue,'Callback',@(s,e)  DistanceMeasurePopup);
        handles.distanceMeasureText=uicontrol('Style','text','Units','normalized','Position',[.20 .98 .1 .02],'String','metric');

        handles.quantizationPopup=uicontrol('Style','Popup','Units','normalized','Position',[.3 .955 .10 .02],'String',quantizationStringList,'Value',quantizationStartingValue,'Callback',@(s,e)  QuantizationPopup);
        handles.quantizationText=uicontrol('Style','text','Units','normalized','Position',[.3 .98 .1 .02],'String','quantization');
        
        handles.OOBRValEditbox=uicontrol('Style','edit','Units','normalized','Position',[.32 .90 .04 .03],'String',num2str(OOBRvalStartingVal),'Callback',@(s,e) OOBREditboxCallback);
        handles.OOBRValText=uicontrol('Style','text','Units','normalized','Position',[.3 .925 .1 .02],'String','OOBRval:');
        
        handles.cutoffsText=uicontrol('Style','text','Units','normalized','Position',[.4 .98 .1 .02],'String','cutoffs (s)');
        handles.cutoffsText1=uicontrol('Style','text','Units','normalized','Position',[.4 .955 .01 .02],'String','-');
        handles.cutoffsText2=uicontrol('Style','text','Units','normalized','Position',[.45 .955 .01 .02],'String','+');
        handles.cutoffTimeEditbox1=uicontrol('Style','edit','Units','normalized','Position',[.41 .95 .04 .03],'String',num2str(cutoffTime1),'Visible','on','Callback',@(s,e) CutoffTime1Callback);
        handles.cutoffTimeEditbox2=uicontrol('Style','edit','Units','normalized','Position',[.46 .95 .04 .03],'String',num2str(cutoffTime2),'Visible','on','Callback',@(s,e) CutoffTime2Callback);
        
        handles.allDatasetsCheckbox=uicontrol('Style','checkbox','String','all datasets','Units','normalized','Position',[.51 .95 .2 .03],'Value',0,'Callback',@(s,e) AllDatasetsCheckboxCallback);

        
        handles.OpenNeuronListWindowButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.7 .95 .1 .03],'String','Neuron List','Callback',@(s,e) OpenNeuronListWindowCallback);
       
        handles.runButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.85 .95 .1 .03],'String','RERUN','Callback',@(s,e) RunButtonCallback);
        handles.saveButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.85 .92 .1 .03],'String','SAVE','Callback',@(s,e) SaveButtonCallback);

    end

    function OpenNeuronListWindowCallback
        
        wbInteractiveNeuronSelector(options.neuronSubset,[],'Select For Clustering',true)

    end

    function SaveClustering
        outStruct.options=options;
        
        %remove handles so we don't save them into cluster file
        if isfield(outStruct.options,'originatingFigureHandle');
            outStruct.options=rmfield(outStruct.options,'originatingFigureHandle');
        end
        
        if isfield(outStruct.options,'existingFigureHandle');
            outStruct.options=rmfield(outStruct.options,'existingFigureHandle');
        end
        
        if ~exist(options.saveDirectory,'dir')
            options.saveDirectory=[pwd filesep 'Quant'];
        end
                    
        if strcmp(options.transitionTypes,'SignedAllFalls')      
            save([options.saveDirectory filesep 'wbClusterFallStruct' flagstr '.mat'],'-struct','outStruct');
            disp('wbTTACluster> wbClusterFallStruct saved');
        else
            save([options.saveDirectory filesep 'wbClusterRiseStruct' flagstr '.mat'],'-struct','outStruct');
            disp('wbTTACluster> wbClusterRiseStruct saved');
        end
        
        
    end

    function AllDatasetsCheckboxCallback
        
        
    end

    function wbInteractiveNeuronSelector(neuronList,existingFigureHandle,panelName,alphabetize)

        liveUpdateFlag=true;
        if nargin<3
            alphabetize=true;
        end


        if nargin<3
            panelName='Neuron Selector';
        end

        height=15*length(neuronList)+100;
        width=120;

        if nargin<2 || isempty(existingFigureHandle)
            mainFigPos=get(handles.mainFig,'Position');
            handles.neuronSelectFig=figure('Position',[mainFigPos(1)+800 mainFigPos(2)  width height],'Name','NeuronSelect Panel','KeyPressFcn',@(s,e) KeyPressedFunction);
        else
            figure(existingFigureHandle);
            handles.neuronSelectFig=existingFigureHandle;
        end

        if alphabetize
            [~,alphaIndex]=sort(neuronList);
        else
            alphaIndex=1:length(neuronList);
        end

        handles.headingText=uicontrol('Style','text','Units','pixel','Position',[5 height-20 width-5 18],'HorizontalAlignment','center','String',panelName);
        handles.includeText=uicontrol('Style','text','Units','pixel','Position',[10 height-40 40 15],'HorizontalAlignment','left','String','incl.');
        handles.phaseText=uicontrol('Style','text','Units','pixel','Position',[30 height-40 40 15],'HorizontalAlignment','left','String','phase+');

        for n=1:length(neuronList)

            handles.includeCheckbox(n)=uicontrol('Style','checkbox','Units','pixel','Position',[10 height-40-15*n  20 15],'Value',options.activeNeuronFlags(alphaIndex(n)),'Callback',@(s,e) wbInteractiveNeuronSelectorIncludeCheckboxCallback(n));
            handles.phaseCheckbox(n)=uicontrol('Style','checkbox','Units','pixel','Position',[30 height-40-15*n  20 15],'Value',options.inPhaseNeuronFlags(alphaIndex(n)),'Callback',@(s,e) wbInteractiveNeuronSelectorInPhaseCheckboxCallback(n));
            handles.neuronName(n)=uicontrol('Style','text','Units','pixel','Position',[50 height-40-15*n 60 15],'HorizontalAlignment','left','String',neuronList{alphaIndex(n)},'Callback',@(s,e) wbInteractiveNeuronSelectorNeuronNameCallback);

        end

        function wbInteractiveNeuronSelectorIncludeCheckboxCallback(n)
            options.activeNeuronFlags(alphaIndex(n))=get(gcbo,'Value');
            
            if liveUpdateFlag
                   GetInputData;
                   DoClustering;
            end
        end

        function wbInteractiveNeuronSelectorInPhaseCheckboxCallback(n)
            options.inPhaseNeuronFlags(alphaIndex(n))=get(gcbo,'Value');
            
            if liveUpdateFlag
                   GetInputData;
                   DoClustering;
            end
            
        end

        function wbInteractiveNeuronSelectorNeuronNameCallback

        end

    end

    function KeyPressedFunction

        liveUpdateFlag=true;
        keyStroke=get(gcbo, 'CurrentKey');
%         get(gcbo, 'CurrentCharacter');
%         get(gcbo, 'CurrentModifier');

        if strcmp(keyStroke,'0')

            options.activeNeuronFlags=false(size(options.activeNeuronFlags));
            set(handles.includeCheckbox,'Value',0);
            if liveUpdateFlag
                   GetInputData;
                   DoClustering;
            end
            
        elseif strcmp(keyStroke,'a')
            
            options.activeNeuronFlags=true(size(options.activeNeuronFlags));
            set(handles.includeCheckbox,'Value',1);
            if liveUpdateFlag
                   GetInputData;
                   DoClustering;
            end
            

        elseif strcmp(keyStroke,'space')
            
        elseif strcmp(keyStroke,'backspace')
            
        elseif strcmp(keyStroke,'equal')
            
        elseif strcmp(keyStroke,'g')

        elseif strcmp(keyStroke,'escape')

        end


    end

    function PreRunLengthCutoffCallback
        
       options.preRunLengthCutoff=str2double(get(gcbo,'String'));
       GetInputData;
       DoClustering;
        
    end

    function OOBREditboxCallback
        
       OOBRval= str2double(get(gcbo,'String'));
       GetInputData;
       DoClustering;
        
    end

    function CutoffTime1Callback
        
        
       cutoffTime1=str2double(get(gcbo,'String'));
       GetInputData;
       DoClustering;
        
    end

    function CutoffTime2Callback
        
       cutoffTime2=str2double(get(gcbo,'String'));
       GetInputData;
       DoClustering;
        
    end

    function AlgorithmPopup
        
        options.clusterAlgorithm=algorithmStringList{get(gcbo,'Value')};
        
        if strcmp(options.clusterAlgorithm,'preRunLength')
            set(handles.preRunLengthCutoffEditbox,'Visible','on');
            set(handles.preRunLengthCutoffText,'Visible','on');
            
        else
            set(handles.preRunLengthCutoffEditbox,'Visible','off');
            set(handles.preRunLengthCutoffText,'Visible','off');            
            
            
        end
        
        DoClustering;
        
    end

    function QuantizationPopup
        
        quantization=get(gcbo,'Value');
        options.quantization=quantizationStringList{quantization};
        
        if quantization==1
            
           set(handles.OOBRValEditbox,'Visible','on');
           set(handles.OOBRValText,'Visible','on');
           
        else
            
           set(handles.OOBRValEditbox,'Visible','off');
           set(handles.OOBRValText,'Visible','off');            
            
        end
        GetInputData;
        DoClustering;

    end

    function RunButtonCallback
        
        DoClustering;
        
    end

    function SaveButtonCallback
    
        SaveClustering;
        
    end

    function MaxClustersPopup
        
        options.maxClusters=get(gcbo,'Value');
        DoClustering;

    end

    function DistanceMeasurePopup
        
        options.distanceMeasure=distanceMeasureStringList{get(gcbo,'Value')};
        DoClustering;
        
    end

    function DoClustering
        
        if strcmp(options.clusterAlgorithm,'hierarchical')
            figure;
            Z=linkage(zeronan(inputValues'),'complete',options.distanceMeasure);
            [H,T,sortIndex]=dendrogram(Z,size(inputValues,2));
            close;

            outStruct.clusterMembership = cluster(Z,options.clusterParam1,options.maxClusters); 
            numClusters=options.maxClusters;
            
        elseif strcmp(options.clusterAlgorithm,'kmeans')

            [outStruct.clusterMembership,outStruct.clusterCenters,outStruct.intraDistanceSums,outStruct.distancesToCentroid]...
                = kmeans(inputValues',options.maxClusters,'Distance',options.distanceMeasure,'emptyaction','drop','Replicates',10);
            outStruct=ReorderClusters(outStruct);
            
            [~,sortIndex]=sort(outStruct.clusterMembership);
            numClusters=options.maxClusters;
            
        elseif strcmp(options.clusterAlgorithm,'kmeansTwoStage');
            
            [outStruct.clusterMembership,outStruct.clusterCenters] = kmeansTwoStage(inputValues',2,options.maxClusters,options.distanceMeasure);
            [~,sortIndex]=sort(outStruct.clusterMembership);
            numClusters=2*options.maxClusters;
            
        elseif strcmp(options.clusterAlgorithm,'preRunLength');

            [outStruct.clusterMembership,outStruct.clusterCenters] = SimpleCutoff(valuesSupplement',options.preRunLengthCutoff);
            [~,sortIndex]=sort(outStruct.clusterMembership);
            numClusters=2;
            
        end
        
        for i=1:numClusters;
           outStruct.clusterIndices{i}=find(outStruct.clusterMembership==i);
        end
        
        %SaveClustering;
        
        if options.interactiveMode
            InteractivePlotResults(outStruct);
        end
                
    end

    function [membership,centers]=SimpleCutoff(inputvals,cutoff)
        
        membership=2*ones(size(inputvals));
        membership(inputvals<cutoff)=1;
        centers(1)=mean(inputvals(membership==1));
        centers(2)=mean(inputvals(membership==2));
        
    end

    function InteractivePlotResults(outStruct)
        
        figure(handles.mainFig);
        cLim=[floor(-cutoffTime1) ceil(cutoffTime2)];
        
        if get(handles.quantizationPopup,'Value')==2 %binary
            cMap=[0 0 0;1 1 1];
            cLim=[0 1];
            
        elseif get(handles.quantizationPopup,'Value')==3 %trinary
            cMap=[1 0 0;0 1 0;0 0 1];
            cLim=[-1 1];
        elseif  get(handles.quantizationPopup,'Value')==4 %precluster
            cMap=[1 0 0;0 1 0;0 0 1];
            cLim=[0 2];

        else
            cMap=jet; %bipolar(201,0.9);
            cLim=[floor(-cutoffTime1) ceil(cutoffTime2)];
            
        end
        
        KillHandle('topAxes',handles);
        handles.topAxes=subtightplot(2,1,1,[0.1 .05],[.1 .1],[.06 .02]);
        RenderMatrix(valuesForPlotting(meanSortIndex,:),cLim,casedLabels(meanSortIndex),cMap,[],[],handles.topAxes);
        
        set(gca,'XTick',1:size(inputValues,2));

        if multiTrialFlag
            set(gca,'XTickLabel',datasetMembership);
        %    trialNames= [ char([TTAStruct.runInfo.dataSets(:)]')' ;repmat('  ',length(TTAStruct.runInfo.dataSets),1)' ];
           trialNames=[];
            xlabel('dataset');

        else
            set(gca,'XTickLabel',1:size(inputValues,2));
                        
            trialNames=wbMakeShortTrialname(refWBstruct.trialname);
            xlabel('transition#');

        end
        
        title(['unclustered: ' trialNames(:)' ]);
        
        KillHandle('middleAxes',handles);
        handles.middleAxes=subtightplot(2,1,2,[0.1 .05],[.1 .1],[.06 .02]);
        RenderMatrix(valuesForPlotting(meanSortIndex,sortIndex),cLim,casedLabels(meanSortIndex),cMap,[],[],handles.middleAxes);
      
        set(gca,'XTick',1:size(inputValues,2));
        
        if multiTrialFlag
            set(gca,'XTickLabel',datasetMembership(sortIndex));
            xlabel('dataset');
        else
            set(gca,'XTickLabel',sortIndex);
        end
        
        title(['clustered params: ' options.distanceMeasure ', ' options.quantization]);
        
        KillHandle('colorbaraxes',handles);
        handles.colorbaraxes=RenderMatrixColorbar('Middle','Left','Horizontal',cLim(1):cLim(2),cMap);
        xlabel('time (s)');

        
        KillHandle('lowerAxes',handles);
        handles.lowerAxes=axes('Position',[.06 .04 .92 .02]);
        RenderMatrix(outStruct.clusterMembership(sortIndex)',[],[],[],[],[],handles.lowerAxes);
        set(handles.lowerAxes,'XTick',1:length(outStruct.clusterMembership'));
        set(handles.lowerAxes,'XTickLabel',outStruct.clusterMembership(sortIndex)');
        xlabel(['cluster#']);
        hold on;
        
        
        %export_fig(['TTACluster-' options.transitionTypes '.pdf']);

%         %%compile heatmaps
%         HPTTAoptions.clusterLabels=outStruct.clusterMembership';
%         HPTTAoptions.sorting=sortIndex;
%         HPTTAoptions.neuronSubset=casedLabels(meanSortIndex);
%         HPTTAoptions.neuronSigns=options.neuronSigns;
%         wbHeatPlotTTA('AVAL',listfolders(pwd),HPTTAoptions);

    end


    
end

