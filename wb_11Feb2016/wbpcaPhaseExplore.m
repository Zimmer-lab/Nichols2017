function wbpcaPhaseExplore(wbstruct,wbpcastruct,options)
% wbpcaPhaseExplore(wbstruct,wbpcastruct,options)
% if wbstruct or wbpcastruct are [] they will load from the Quant
% folder.
%
%to modify coloring params, call with
%options.coloringFunctionParams={thresh,smoothingWindow,threshType};
%wbpcaPhaseExplore([],[],options)
%

if nargin<1 || isempty(wbstruct)
    wbstruct=wbload;
end

if nargin<2 || isempty(wbpcastruct)
    try
        load('Quant/wbpcastruct.mat');
    catch
        disp('could not find wbpcastruct.mat');
    end
end

if ischar(wbpcastruct)
    wbpcastruct_temp=load(wbpcastruct);
    wbpcastruct=wbpcastruct_temp.wbpcastruct;
end

if nargin<3 || isempty(options)
    options=[];
end

if ~isfield(options,'savePDFCopyDirectory')
    options.savePDFCopyDirectory=pwd;
end

if ~isfield(options,'coloringFunctionParams')
    options.coloringFunctionParams=[];
end

if ~isfield(options,'coloringFunctionHandle')
    options.coloringFunctionHandle=@traceDerivIsPositive;
end

if ~isfield(options,'rangeRel')
    options.rangeRel=1:length(wbstruct.tv);
end

   %whitebg([1 1 1]);
   whitebg('white');
   
   nList=wbListIDs(wbstruct);
   %nList(1)=[];

   pcnum1=1;
   pcnum2=2;
   pcnum3=3;
   plotTimeRangeRel=options.rangeRel;  %360:2000;
    
   for n=1:6
       
       fullstimcoloring(n,:)=wbgetstimcoloring(wbstruct,n);
       onsetstimcoloring(n,:)=wbgetstimcoloring(wbstruct,n,2);

       relstimcoloring(n,:)=fullstimcoloring(n,plotTimeRangeRel);
       relonsetstimcoloring(n,:)=onsetstimcoloring(n,plotTimeRangeRel);
       
       fullstimcoloring_neg(n,:)=wbgetstimcoloring(wbstruct,n,[],1);
       relstimcoloring_neg(n,:)=fullstimcoloring_neg(n,plotTimeRangeRel);
     
   end
   
   plotExclusions=[];

   forPlotting.pcs.PC_D1=wbpcastruct.pcs.PC_D1;
   forPlotting.pcs.PC_D1(:,plotExclusions)=[];
    
   PC{1}=forPlotting.pcs.PC_D1(:,pcnum1);
   PC{2}=forPlotting.pcs.PC_D1(:,pcnum2);
   PC{3}=forPlotting.pcs.PC_D1(:,pcnum3);
    
   combo=[1 2; 1 3; 2 3];
    
   for j=1:3
        
        pcnumx=combo(j,1);
        pcnumy=combo(j,2);

        PCX=PC{pcnumx};
        PCY=PC{pcnumy};

        nr=ceil(sqrt(length(nList))); 
        
        figure('Position',[0 0 1600 1200],'Color','w');

        for n=[1:length(nList)]
             nList{n};

             coloring=wbgettimecoloring(wbstruct,nList{n},options.coloringFunctionHandle,options.coloringFunctionParams);
             coloring=coloring(plotTimeRangeRel);

             subtightplot(nr,nr,n);
             plot(PCX,PCY,'Color',[0.5 0.5 0.5]);
             hold on;
             for m=1:6
                 plot(PCX(logical(relstimcoloring(m,:))),PCY(logical(relstimcoloring(m,:))),'r','LineWidth',1);
                 plot(PCX(logical(relstimcoloring_neg(m,:))),PCY(logical(relstimcoloring_neg(m,:))),'b','LineWidth',1);
                 %plot(PCX(logical(relonsetstimcoloring(m,:))),PCY(logical(relonsetstimcoloring(m,:))),'b','LineWidth',3);
             end

             hold on;
             plot(PCX(logical(coloring)),PCY(logical(coloring)),'.g','MarkerSize',12);

             %color_line3(PC1,PC2,PC3,coloring);
             axis off;

             intitle(nList{n});
        end

        for n2=(n+1):(nr^2)
            subtightplot(nr,nr,n2); axis off;
        end
   

        mtit([wbstruct.displayname ': PCderiv' num2str(pcnumx) ' vs  PCderiv' num2str(pcnumy) ',  d/dt>0 '],'fontsize',16,'color',[1 0 0]);

        %color by stimulus

        %end

        export_fig(['NeuronPhasePlots-' wbstruct.trialname '-PCd' num2str(pcnumx) 'vsPCd' num2str(pcnumy) '.pdf']);
        if ~isempty(options.savePDFCopyDirectory)
            export_fig([options.savePDFCopyDirectory filesep 'NeuronPhasePlots-' wbstruct.trialname '-PCd' num2str(pcnumx) 'vsPCd' num2str(pcnumy) '.pdf']);
        end

    end
    
end
    