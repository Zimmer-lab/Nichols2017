function [labels, values, yLimits]=wbPlotSortingColumn(wbstruct,options,sortLabelsOptions)
%one column plot of a given sorting
%used by wbCompareSortings
%

if nargin<1 || isempty(wbstruct)
    wbstruct=wbload([],false);
end

if nargin<2
    options=[];
end

if nargin<3
    sortLabelsOptions=[];
end


if  ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if  ~isfield(options,'sortMethod')
    options.sortMethod='power';
end

if  ~isfield(options,'useOnlyIDedNeurons')
    options.useOnlyIDedNeurons=true;
end

if  ~isfield(options,'useForSubplot')
    options.useForSubplot=false;
end

if  ~isfield(options,'sortingLabel')
    options.sortingLabel='sorting 1';
end

if  ~isfield(options,'ySpacing');
    options.ySpacing=1;
end

if  ~isfield(options,'xPos')
    options.xPos=0;
end

if ~isfield(options,'useValueNotRank')
    options.useValueNotRank=false;
end

if ~isfield(sortLabelsOptions,'sortMethod')
    sortLabelsOptions.sortMethod=options.sortMethod;
end

if ~isfield(sortLabelsOptions,'useOnlyIDedNeurons')
    sortLabelsOptions.useOnlyIDedNeurons=options.useOnlyIDedNeurons;
end

[labels, values]=wbSortLabels(wbstruct,sortLabelsOptions);

if ~options.useForSubplot
    figure('Position',[0 0 100 1000]);
    subtightplot(1,1,1,[],[],[.2 .2]);
    set(gca,'TickDir','out');
end

if ~options.useValueNotRank
    for i=1:length(labels)
        text(options.xPos,options.ySpacing*i,labels{i},'HorizontalAlignment','center');
        hold on;
    end
    yLimits=[1 length(labels)];
    set(gca,'YDir','reverse');

else
    for i=1:length(labels)
        text(options.xPos,options.ySpacing*values(i),labels{i},'HorizontalAlignment','center');
        hold on;
    end
    yLimits=[min(values) max(values)];
    
end


if ~options.useForSubplot
    xlim([options.xPos-.1,options.xPos+.1]);
    if ~options.useValueNotRank
        ylim([options.ySpacing/2,options.ySpacing*length(labels)+options.ySpacing/2]);
    end
    set(gca,'YTick',1:length(labels));
    set(gca,'XTickLabel',options.sortingLabel);
    set(gca,'XTick',options.xPos);
end






%function [tracesSorted,sortIndex,sortVal,extraAnalysisData,reducedSortIndex]=wbSortTraces(alltraces,sortMethod,exclusionList,sortParam,options)
