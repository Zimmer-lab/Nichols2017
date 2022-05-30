function outStruct=wbComparePCAPairwise(folder1,folder2,options)

if nargin<1
    folder1='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140127d_lite-1_punc-31_NLS3_4eggs_56um_basal21plus6stim';
end

if nargin<2
    folder2='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140725b_lite-1_punc-31_NLS3_AVB_AIY_AIA_4eggs_56um_1mMTet_basalplus6stim_720s';
end

if nargin<3
    options=[];
end

if ~isfield(options,'neuronSubsetOverride')
    options.neuronSubsetOverride=[];
end

if ~isfield(options,'useSavedPCA')
    options.useSavedPCA=true;
end

if ~isempty(options.neuronSubsetOverride)
    options.useSavedPCA=false;
end

if ~isfield(options,'plotFlag')
    options.plotFlag=false;  %launch wbPlotPCA afterward
end

computePCAoptions=wbPCADefaultOptions;
computePCAoptions.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR','ASHR','ASHL'};
computePCAoptions.saveFlag=false;  %save wbpcastruct.mat and wbpcastruct-<details>.mat


wbstructs{1}=wbload(folder1,false);
wbstructs{2}=wbload(folder2,false);

if isempty(options.neuronSubsetOverride)
    overlapList=wbListIDsInCommon(wbstructs);
else
    overlapList=options.neuronSubsetOverride;
end

pcastruct=ForEachFolder({folder1,folder2},@wbComputePCA,{[],computePCAoptions});
computePCAoptions.neuronSubset=overlapList;
pcastruct_intersect=ForEachFolder({folder1,folder2},@wbComputePCA,{[],computePCAoptions});


% for i=1:2
%     
%     options.neuronSubset=[];
%     
%     if options.useSavedPCA
%         pcastruct{i}=loadPCA(folder1);
%     else
%         pcastruct{i}=wbComputePCA(wbstructs{i},computePCAoptions);
%     end
%     
%     computePCAoptions.neuronSubset=overlapList;
%     pcastruct_intersect{i}=wbComputePCA(wbstructs{i},computePCAoptions);
%     
% end

outStruct.nOverlap=size(pcastruct_intersect{1}.coeffs,2);


%% plots


options.plotNumComps=8;

if options.plotFlag
    
    figure('Position',[0 0 2000 1000]);
    nr=2;
    nc=2;
    options.lineWidth=1;

    for i=1:2

        options.plotTimeRange=pcastruct_intersect{i}.options.range;
        subtightplot(nr,nc,i,[0.05 0.05]);
        for nn=1:options.plotNumComps
            hline(options.plotNumComps-nn+1);
            hold on;
            plot(wbstructs{i}.tv(options.plotTimeRange),(options.plotNumComps-nn+1)+0.75*normalize(detrend(cumsum(pcastruct{i}.pcs(options.plotTimeRange,nn)))),'LineWidth',options.lineWidth);

        end
        title(['dataset ' num2str(i)  ' all IDs']);
        xlim([ wbstructs{i}.tv(options.plotTimeRange(1)) wbstructs{i}.tv(options.plotTimeRange(end))]);
        ylim([0 options.plotNumComps+1]);

        options.plotTimeRange=pcastruct_intersect{i}.options.range;
        subtightplot(nr,nc,i+2,[0.05 0.05]);
        for nn=1:options.plotNumComps
            hline(options.plotNumComps-nn+1);
            hold on;
            plot(wbstructs{i}.tv(options.plotTimeRange),(options.plotNumComps-nn+1)+0.75*normalize(detrend(cumsum(pcastruct_intersect{i}.pcs(options.plotTimeRange,nn)))),'LineWidth',options.lineWidth);

        end
        title(['dataset' num2str(i) ' common IDs']);
        xlim([ wbstructs{i}.tv(options.plotTimeRange(1)) wbstructs{i}.tv(options.plotTimeRange(end))]);
        ylim([0 options.plotNumComps+1]);


    end

end
%% sort coeffs by global index 
overlapList_ordering1=wbListIDs(wbstructs{1},[],pcastruct_intersect{1}.referenceIndices);
overlapList_ordering2=wbListIDs(wbstructs{2},[],pcastruct_intersect{2}.referenceIndices);

sortByGlobalIndex1=wbSortByGlobalNeuronNumber(overlapList_ordering1);
sortByGlobalIndex2=wbSortByGlobalNeuronNumber(overlapList_ordering2);

outStruct.PCAi{1}.coeffs=pcastruct_intersect{1}.coeffs(sortByGlobalIndex1,:);
outStruct.PCAi{2}.coeffs=pcastruct_intersect{2}.coeffs(sortByGlobalIndex2,:);

outStruct.PCAi{1}.pcs=pcastruct_intersect{1}.pcs;
outStruct.PCAi{2}.pcs=pcastruct_intersect{2}.pcs;


outStruct.neuronLabels=overlapList_ordering1(sortByGlobalIndex1);

%% compute correlation coefficient
for pc=1:size(pcastruct_intersect{1}.coeffs,2)
     thiscc=corrcoef(pcastruct_intersect{1}.coeffs(sortByGlobalIndex1,pc),pcastruct_intersect{2}.coeffs(sortByGlobalIndex2,pc));
     outStruct.cc(pc)=thiscc(2,1);
end

%% bar

if options.plotFlag
    
    figure;
    subplot(2,1,1);
    pc=1;
    bar(pcastruct_intersect{1}.coeffs(sortByGlobalIndex1,pc));
    set(gca,'XTickLabel',overlapList_ordering1(sortByGlobalIndex1));
    set(gca,'XTick',1:length(sortByGlobalIndex1));
    xlim([0.5 length(sortByGlobalIndex1)+0.5]);
    rotateXLabels(gca,90);
    subplot(2,1,2);
    bar(-pcastruct_intersect{2}.coeffs(sortByGlobalIndex2,pc));
    set(gca,'XTickLabel',overlapList_ordering2(sortByGlobalIndex2));
    set(gca,'XTick',1:length(sortByGlobalIndex2));
    xlim([0.5 length(sortByGlobalIndex2)+0.5]);
    rotateXLabels(gca,90);
end

%% scatter

if options.plotFlag
    
    figure;
    for i=1:6
        subplot(2,3,i);
    plot(pcastruct_intersect{1}.coeffs(sortByGlobalIndex1,i),pcastruct_intersect{2}.coeffs(sortByGlobalIndex2,i),'.','MarkerSize',14);
    plot(pcastruct_intersect{1}.coeffs(sortByGlobalIndex1,i),pcastruct_intersect{2}.coeffs(sortByGlobalIndex2,i),'.','MarkerSize',14);

    title(['pc# ' num2str(i)]);

    end

    
end

%%
%refer to
%wbComparePCs({folder1,folder2},options);
