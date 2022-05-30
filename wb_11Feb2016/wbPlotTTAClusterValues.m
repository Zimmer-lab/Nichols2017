function wbPlotTTAClusterValues(newFig,subplotParams,options)
%heatplot of cluster input values
%
%
%
if nargin<3
    options=[];
end

if ~isfield(options,'pValues')
    options.pValues=[];
end


if nargin<1 
    newFig=1;
end

if ~isempty(newFig)
    figure('Position',[0 0 500 1000]);
end

folders=listfolders(pwd,true);
nd=numel(folders);


for i=1:nd
    
    currentFolderFullPath=folders{i};       
    cs(1)=load([currentFolderFullPath filesep 'Quant' filesep 'wbClusterRiseStruct.mat']);
    cs(2)=load([currentFolderFullPath filesep 'Quant' filesep 'wbClusterFallStruct.mat']);
       
    for j=1:2
    
       if isempty(newFig)
            subtightplot(nd,4,2+j+4*(i-1),subplotParams.gaps,subplotParams.hmar,subplotParams.wmar);
       else
            subtightplot(nd,2,j+2*(i-1),[.025,.085],[.05 .05],[.1 .05]);
       end
       inputValues=cs(j).inputValues;

       inputValues(inputValues>9)=nan;
       inputValues(inputValues<-9)=nan;

       if j==1 && i==nd
           inputValues(inputValues==0)=nan;

       end

       means=nanmean(inputValues,2);
       [meansSorted,vertSortIndex]=sort(means);

       casedLabels=cs(j).inputLabels;

       [~,vertSortIndex]=sort(casedLabels);

       cLim=[-7 7];
       cMap=redblue(64); %bipolar(63,0.9); %jet

       [~,sortIndex]=sort(cs(j).clusterMembership);

       RenderMatrix(inputValues(vertSortIndex,sortIndex),cLim,casedLabels(vertSortIndex),cMap,[],[],[],[0.4 0.4 0.4]);
       %RenderMatrix(inputValues,cLim,casedLabels(meanSortIndex),cMap,[],[],[]);

       set(gca,'XTick',1:size(inputValues,2));
       set(gca,'XTickLabel',sort(cs(j).clusterMembership));
       set(gca,'FontSize',6);
       
       if isempty(options.pValues)
            title(['Trial ' num2str(i)]);
       else 
            title(['Trial ' num2str(i) '  P<' num2str(options.pValues(i,j))]);
       end
       
       if i==nd
           if j==1
            xlabel('Rise transition cluster');
           else
            xlabel('Fall transition cluster');
           end
    end

end


box off;

end