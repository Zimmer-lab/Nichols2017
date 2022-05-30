function [globalCoeff globalCoeffUnlabeled datasetShortname globalCovMat]=wbGlobalPCA(wbstructFileNameCellArray,options)

if nargin<2 || isempty(options)
    options=[];
end

if ~isfield(options,'plotFlag')
    options.plotFlag=true;
end

includeUnlabeledFlag=false;

numPCs=5;

globalNeuronNames=LoadGlobalNeuronIDs;

if nargin<1
    wbstructFileNameCellArray=listfolders;
end

disp('processing...');


globalCovMat.covMat=NaN(length(globalNeuronNames),length(globalNeuronNames),length(wbstructFileNameCellArray));

for i=1:length(wbstructFileNameCellArray)
    
    disp(['dataset #' num2str(i) '/' num2str(length(wbstructFileNameCellArray)) ':  ' wbstructFileNameCellArray{i}]); 
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
    
    %compile Coeffs and CovMat
    for pc=1:numPCs
        j=1;
        k=1;
        clear thisGlobalIndex;
        for n=1:size(wbpcastruct{i}.coeffs,1)

            if isempty(wbstruct{i}.simple.ID{wbpcastruct{i}.referenceIndices(n)})   ||...
                strcmp(wbstruct{i}.simple.ID{wbpcastruct{i}.referenceIndices(n)}{1},'---')
                
                globalCoeffUnlabeled{i}(k,pc)=wbpcastruct{i}.coeffs( n ,pc);
                k=k+1;

            else
%wbstruct{i}.simple.ID{wbpcastruct{i}.referenceIndices(n)}{1}
                thisGlobalIndex(j)=find(strcmp( globalNeuronNames, wbstruct{i}.simple.ID{wbpcastruct{i}.referenceIndices(n)}{1}));
                globalCoeff{i}(thisGlobalIndex(j),pc)=wbpcastruct{i}.coeffs( n ,pc);
                j=j+1;
            end


        end
        
        %add labeled Cov entries to global Cov Matrix
        if pc==1
            labeledSubsetLogical=~(cellfun(@isempty,wbListIDs(wbstruct{i})) | ismember(wbListIDs(wbstruct{i}),wbpcastruct{i}.options.extraExclusionList));
% sum(labeledSubsetLogical)
% length(thisGlobalIndex)
            globalCovMat.covMat(thisGlobalIndex,thisGlobalIndex,i)=wbpcastruct{i}.covMat(labeledSubsetLogical,labeledSubsetLogical);
        end
    end
    
    datasetShortname{i}=wbMakeShortTrialname(wbstruct{i}.trialname);
    datasetShortname{i}=datasetShortname{i}(end-4:end);  
    
end

globalCovMat.covMat_mean=nanmean(globalCovMat.covMat,3);

validNeuronLogical=~isnan(diag(globalCovMat.covMat_mean));

globalCovMat.mean_packed=globalCovMat.covMat_mean(validNeuronLogical,validNeuronLogical);

globalCovMat.neuronIndicesOccupied=find(validNeuronLogical);
globalCovMat.mean_packed_labels=globalNeuronNames(validNeuronLogical);

wbGlobalPCAstruct.globalCoeff = globalCoeff;
wbGlobalPCAstruct.globalCoeffUnlabeled = globalCoeffUnlabeled ;
wbGlobalPCAstruct.datasetShortname = datasetShortname ;
wbGlobalPCAstruct.globalCovMat = globalCovMat;

[wbGlobalPCAstruct.jointPCA.coeffs, wbGlobalPCAstruct.jointPCA.latent, wbGlobalPCAstruct.jointPCA.varianceExplained] = pcacov(zeronan(globalCovMat.mean_packed));

%compute PC reconstructions
for i=1:length(wbstructFileNameCellArray)

    disp(['recon dataset #' num2str(i) '/' num2str(length(wbstructFileNameCellArray)) ':  ' wbstructFileNameCellArray{i}]); 

    thisIDs=wbListIDs(wbstruct{i}); 
    unexcludedNeurons=thisIDs(~ismember(thisIDs,wbpcastruct{i}.options.extraExclusionList));
    [thisTraces,traceIndices]=wbGetTraces(wbstruct{i},true,'deltaFOverF',unexcludedNeurons);

    for pc=1:numPCs
        clear thisGlobalCoeff;
         for j=1:length(traceIndices)
                thisPackedIndex=find(strcmp(globalCovMat.mean_packed_labels,unexcludedNeurons{j}));
                thisGlobalCoeff(j)=wbGlobalPCAstruct.jointPCA.coeffs(  thisPackedIndex,pc);
         end    
         

         wbGlobalPCAstruct.jointPCA.pcs{i}(:,pc) =( thisTraces*thisGlobalCoeff')';
    end
end %i


wbGlobalPCAstruct.dateRan=datestr(now);

save('wbGlobalPCAstruct.mat','-struct','wbGlobalPCAstruct');

%% plotting
if options.plotFlag

    [allIDs allGlobalNeuronNumbers]=wbListIDsInCommon(wbstructFileNameCellArray,'union');

    
    for pc=1:numPCs
        


        figure('Position',[pc*10 pc*10 1200 800]);
        nr=length(wbstructFileNameCellArray)+1; %bottom row will be JointPCA
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
            end

            set(gca,'XTickLabel',[]);
                

            
            ylabel(datasetShortname{i});
        end
        

        %plot JointPCA coefficients
        subtightplot(nr,1,i+1);
        bar(wbGlobalPCAstruct.jointPCA.coeffs(:,pc));

        ylabel('Joint');
        set(gca,'XTick',1:length(allIDs));
        xlim([0.5 maxwidth+0.5]);
            
                   
        set(gca,'XTickLabel',allIDs);
        rotateXLabels(gca,90);
            
        drawnow;
        export_fig(['All_PCCoeffsID-PC' num2str(pc) '.pdf']);

        
    end
    
    for pc=1:numPCs
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
    
    %plot JointPCA PCs
    for pc=1:numPCs;
        figure('Position',[pc*10 pc*10 1200 800]);
        nr=length(wbstructFileNameCellArray);
        
        for i=1:length(wbstructFileNameCellArray)

            subtightplot(nr,1,i);
            hold on;
            
            tv=mtv(wbGlobalPCAstruct.jointPCA.pcs{i}(:,pc),1/wbstruct{i}.fps);
            plot(tv,wbGlobalPCAstruct.jointPCA.pcs{i}(:,pc));
            xlim([tv(1) tv(end)]);
            ylim([min(wbGlobalPCAstruct.jointPCA.pcs{i}(:,pc)) max(wbGlobalPCAstruct.jointPCA.pcs{i}(:,pc))]);
            SmartTimeAxis([tv(1) tv(end)]);


            if i==1
                title(['JointPC# ' num2str(pc)]);

            end
            
            ylabel(datasetShortname{i});
        end
        

        drawnow;
        export_fig(['All_JointPCs-PC' num2str(pc) '.pdf']);

        
    end


end
    




end