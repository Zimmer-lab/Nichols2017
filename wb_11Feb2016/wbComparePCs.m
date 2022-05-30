function [globalCoeff globalCoeffUnlabeled datasetShortname]=wbComparePCs(wbstructFileNameCellArray,options)

if nargin<2 || isempty(options)
    options=[];
end

if ~isfield(options,'plotFlag')
    options.plotFlag=true;
end


useExclusionListFlag=true;
includeUnlabeledFlag=false;

numPCs=5;

globalNeuronNames=LoadGlobalNeuronIDs;

if nargin<1
    wbstructFileNameCellArray=listfolders;
end

disp('processing...');

for i=1:length(wbstructFileNameCellArray)
      
    wbstruct{i}=wbload(wbstructFileNameCellArray{i},false); 
    wbpcastruct{i}=wbLoadPCA(wbstructFileNameCellArray{i},false);
    [neuronString{i} neuronNumber{i}]=wbListIDs(wbstruct{i},includeUnlabeledFlag);
    
    
    if i==1
        overlapNeurons=neuronString{1};
    else
        overlapNeurons= overlapNeurons( ismember(overlapNeurons,neuronString{i}));
    end
    
    
    
    globalCoeff{i}=NaN(length(globalNeuronNames),numPCs);
    globalCoeffUnlabeled{i}=NaN;
    
    for pc=1:numPCs
        
        k=1;
        
        for n=1:size(wbpcastruct{i}.coeffs,1)


            if isempty(wbstruct{i}.simple.ID{wbpcastruct{i}.referenceIndices(n)})
                
                globalCoeffUnlabeled{i}(k,pc)=wbpcastruct{i}.coeffs( n ,pc);
                k=k+1;

            else

                thisGlobalIndex=find(strcmp( globalNeuronNames, wbstruct{i}.simple.ID{wbpcastruct{i}.referenceIndices(n)}{1}));
                globalCoeff{i}(thisGlobalIndex,pc)=wbpcastruct{i}.coeffs( n ,pc);

            end


        end
    
    end
    
    datasetShortname{i}=wbMakeShortTrialname(wbstruct{i}.trialname);
    datasetShortname{i}=datasetShortname{i}(end-4:end);  
    
end

if options.plotFlag

    [allIDs allGlobalNeuronNumbers]=wbListIDsInCommon(wbstructFileNameCellArray,'union');

    
    for pc=1:numPCs
        


        figure('Position',[pc*10 pc*10 1200 800]);
        nr=length(wbstructFileNameCellArray);
        maxwidth=1;
        for i=1:length(wbstructFileNameCellArray)
            maxwidth=max([maxwidth length( [globalCoeff{i}(allGlobalNeuronNumbers,pc); globalCoeffUnlabeled{i}(:,pc)] )]);
        end
        
        
        for i=1:length(wbstructFileNameCellArray)

            subtightplot(nr,1,i);
            hold on;
            
%           gray center vertical grid lines
%           for k=1:length(allIDs);
%               line([k k],[-1 1],'Color',[0.9 0.9 0.9]);
%           end
            
            bar([globalCoeff{i}(allGlobalNeuronNumbers,pc); sort(globalCoeffUnlabeled{i}(:,pc),1,'descend')]);

            nanVals=(find(isnan(globalCoeff{i}(allGlobalNeuronNumbers,pc))  ))';

            for j=nanVals
                rectangle('Position',[j-0.5, -1, 1, 2], 'FaceColor',[0.9 0.9 0.9],'EdgeColor','none');
            end
                
            set(gca,'XTick',1:length(allIDs));
            xlim([0.5 maxwidth+0.5]);

            if i==1
                title(['PC# ' num2str(pc)]);
                set(gca,'XTick',[]);
            end

            if i<length(wbstructFileNameCellArray)
                set(gca,'XTick',[]);
                
            else
                set(gca,'XTickLabel',allIDs);
                rotateXLabels(gca,90);
            end
            
            ylabel(datasetShortname{i});
        end
        

        drawnow;
        export_fig(['All_PCCoeffsID-PC' num2str(pc) '.pdf']);

        
    end
    
    for pc=1:numPCs;
        figure('Position',[pc*10 pc*10 1200 800]);
        nr=length(wbstructFileNameCellArray);
        
        for i=1:length(wbstructFileNameCellArray)

            subtightplot(nr,1,i);
            hold on;
            
            tv=mtv(wbpcastruct{i}.pcs(:,pc),1/wbstruct{i}.fps);
            plot(tv,cumsum(wbpcastruct{i}.pcs(:,pc)));
            xlim([tv(1) tv(end)]);
            ylim([min(cumsum(wbpcastruct{i}.pcs(:,pc))) max(cumsum(wbpcastruct{i}.pcs(:,pc)))]);
            SmartTimeAxis([tv(1) tv(end)]);


            if i==1
                title(['PC# ' num2str(pc)]);

            end
            
            ylabel(datasetShortname{i});
        end
        

        drawnow;
        export_fig(['All_PCs-PC' num2str(pc) '.pdf']);

        
    end


end
    




end