function [Q,sortedLabels]=wbMatrixPlot(wbstruct,options)
%Q=wbMatrixPlot(wbstruct,options)
%plot a pairwise relational matrix between neurons
%

if nargin<1 || isempty(wbstruct)
    wbstruct=wbload([],false);
end

if nargin<2
    options=[];
end

%%OPTION DEFAULTS
if  ~isfield(options,'cLim')
    options.cLim=[]; 
end

if  ~isfield(options,'colorMap')
    options.colorMap=jet; 
end

if  ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if  ~isfield(options,'relation')
    options.relation='corrd'; 
end

if  ~isfield(options,'relationParams')
    options.relationParams=[]; 
end

if  ~isfield(options,'showLabels')
    options.showLabels=true; 
end

if  ~isfield(options,'useOnlyIDedNeurons')
    options.useOnlyIDedNeurons=false; 
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset=[];
end

if  ~isfield(options,'sortMethod')
    options.sortMethod='none';
end

if  ~isfield(options,'useSavedMatrixData')
    options.useSavedMatrixData=true;
end

if  ~isfield(options,'matrixDataFile')
    options.matrixDataFile=[pwd filesep 'Quant' filesep 'wbmatrixstruct.mat'];
end

if ~isfield(options,'postProcessingFunction')
    options.postProcessingFunction=[];
end

if ~isfield(options,'postProcessingFunctionParams')
    options.postProcessingFunctionParams=[];
end

if ~isfield(options,'clickable')
    options.clickable=false;
end

if ~isfield(options,'blackOutDiagonal')
    options.blackOutDiagonal=false;
end

if ~isfield(options,'caseLabelsByNeuronSign')   %will autoload pca data
    options.caseLabelsByNeuronSign=true;
end

%%save options
if nargin<2 || ~isfield(options,'saveDir')
    if exist([pwd '/Quant'],'dir')==7
        options.saveDir=([pwd '/Quant']);
    else
        options.saveDir=pwd;
    end
end

if nargin<2 || ~isfield(options,'saveFlag')
    options.saveFlag=1;
end

%%MAIN 
auxFigHandle=[];
h_rect=[];
flagstr=[];

if options.useSavedMatrixData
    
    Qstruct=load(options.matrixDataFile);
    Q=Qstruct.(options.relation);
    
end

if length(options.sortMethod)>5 && strcmp(options.sortMethod(1:6),'custom')
    sortOptions.customMatrix=Q;
else
    sortOptions=[];
end


if ~strcmp(options.sortMethod,'none')
    [tracesSorted,sortIndex,~,~,reducedSortIndex]=wbSortTraces(wbstruct.(options.fieldName),options.sortMethod,wbstruct.exclusionList,[],sortOptions);
    tracesSorted=tracesSorted(:,1:end-length(wbstruct.exclusionList)); %remove excluded neurons
    
    %need to handle neuronSubset with sorting here
    
else
    if isempty(options.neuronSubset)
        tracesSorted=wbstruct.simple.(options.fieldName);
        reducedSortIndex=1:wbstruct.simple.nn;
    else
        if isnumeric(options.neuronSubset)
            reducedSortIndex=options.neuronSubset;
        end
    end
end

if options.useSavedMatrixData
    Q=Q(reducedSortIndex,reducedSortIndex);
    %Q=Q(:,reducedSortIndex);
else
    %Q=wbComputeRelationMatrix(tracesSorted,options.relation);
    Q=wbComputeRelationMatrix(wbstruct,options.relation,options,options.relationParams);
end

if ~isempty(options.postProcessingFunction)
    Q=options.postProcessingFunction(Q,options.postProcessingFunctionParams);
    flagstr=[flagstr '-pp' num2str(options.postProcessingFunctionParams(1))];
end

figure('Position',[0 0 1024 1024]);
subtightplot(1,1,1,[],[.01 .1],[.1 .01]);

if isempty(options.cLim)
    imf=imagesc(Q);
    colorbar;
else
    imf=imagesc(Q,options.cLim);
    colormap([options.colorMap]);
    hcb=colorbar;
    set(hcb,'YTick',ceil(options.cLim(1)):floor(options.cLim(end)));
end

if options.blackOutDiagonal
    BlackOutDiagonal(size(Q,1));
end



if options.clickable
    set(imf,'HitTest','off');
    set(get(imf,'Parent'), 'ButtonDownFcn',@mouseDownCallback);
end

set(gca,'XTick',1:size(Q,1));
set(gca,'YTick',1:size(Q,1));

sortIndexLabelX={};  %Stag=visually stagggered 
sortIndexLabelY={};


if options.useOnlyIDedNeurons
    
    for i=1:length(reducedSortIndex)
        
        if ~isempty(wbstruct.simple.ID{reducedSortIndex(i)})
             thisLabel=wbstruct.simple.ID{reducedSortIndex(i)}{1};
             if options.caseLabelsByNeuronSign
                 thisLabel=wbSetLabelCaseByNeuronSign(thisLabel,[],wbstruct);
             end
             sortIndexLabelX=[sortIndexLabelX, ['   ' thisLabel]];
             sortIndexLabelY=[sortIndexLabelY, thisLabel];
        end
    end

else
    
    for i=1:length(reducedSortIndex);

        thisLabel=num2str(reducedSortIndex(i));

        if options.showLabels

            if ~isempty(wbstruct.simple.ID{reducedSortIndex(i)})
                thisLabel=wbstruct.simple.ID{reducedSortIndex(i)}{1};
                if options.caseLabelsByNeuronSign
                   thisLabel=wbSetLabelCaseByNeuronSign(thisLabel,[],wbstruct);
                end
            end
        end

        if mod(i,2)
            sortIndexLabelX=[sortIndexLabelX, ['   ' thisLabel ] ];
            sortIndexLabelY=[sortIndexLabelY, [thisLabel '      '] ];
        else
            sortIndexLabelX=[sortIndexLabelX, ['      ' thisLabel] ];
            sortIndexLabelY=[sortIndexLabelY, [thisLabel ] ];

        end
    end

end



set(gca,'XAxisLocation','top');
set(gca,'XTickLabel',sortIndexLabelX);
set(gca,'YTickLabel',sortIndexLabelY);
set(gca,'TickDir','out');
set(gca,'TickLength',[0.007 0.007]);
axis square;
rotateXLabelsImage(gca(),90);

sortedLabels=sortIndexLabelY;


title([wbMakeShortTrialname(wbstruct.trialname) ' ' options.relation ' matrix sorted by ' strrep(options.sortMethod,'_','\_') ' ' flagstr]); %,'Position',[0.5 1.5 0]);

if options.saveFlag
    export_fig([options.saveDir filesep 'wbMatrixPlot-' wbMakeShortTrialname(wbstruct.trialname) '-' options.relation '-sortby-' options.sortMethod flagstr],'-tif','-a1');
    saveas(imf, [options.saveDir filesep 'wbMatrixPlot-' wbMakeShortTrialname(wbstruct.trialname) '-' options.relation '-sortby-' options.sortMethod  flagstr '.fig'], 'fig');

end

    function mouseDownCallback(hObject,~)
        
        cursorPoint = get(hObject, 'CurrentPoint'); 
        row = round(cursorPoint(1,1));
        col = round(cursorPoint(1,2));
        
        hold on;
        if ~isempty(h_rect)
            set(h_rect,'Position',[row-.5 col-.5 1 1]);
            %set(h_ex,'XData',row);
            %set(h_ex,'YData',col);
        else
            h_rect=rectangle('Position',[row-.5 col-.5 1 1]);
            %h_ex=ex(row,col);
        end
       
        thisoptions.inputLabel=num2str(reducedSortIndex(row));
        if ~isempty(wbstruct.simple.ID{reducedSortIndex(row)})
              thisoptions.inputLabel=wbstruct.simple.ID{reducedSortIndex(row)}{1};
        end
        
        thisoptions.outputLabel=num2str(reducedSortIndex(col));
        if ~isempty(wbstruct.simple.ID{reducedSortIndex(col)})
              thisoptions.outputLabel=wbstruct.simple.ID{reducedSortIndex(col)}{1};
        end

        if ~isempty(auxFigHandle)
            figure(auxFigHandle);
            clf;
        else
            auxFigHandle=figure('Position',[500 0 800 600]);
        end
        
        thisoptions.makePlotFlag=1;
        
        wbLN(wbstruct,reducedSortIndex(row),reducedSortIndex(col),thisoptions);
        
    end



end