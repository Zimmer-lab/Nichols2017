function [tracesSorted,sortIndex,sortVal,extraAnalysisData,reducedSortIndex]=wbSortTraces(alltraces,sortMethod,exclusionList,sortParam,options)
%wbSortTraces(alltraces,sortMethod,exclusionList)
%type wbSortTraces('?') for list of sortMethods
%
%traces should be column vectors
%
%if wbsorttraces('get') is called
%a cell array of strings with the sort types is returned
%
reducedSortIndex=[];
extraAnalysisData=[];
sortVal=[];
tracesSorted=[];
sortIndex=[];

 %argument overloading for help function
 if nargin==1 && ischar(alltraces) 
     sortTypes={'position','tta','power','f0','power_detrended','power_offset','power_detrended_offset','power_detrended_offset_rel',...
         'corrcluster','covcluster','covsvd','corrdcluster',...
         'pcaloading1','pcaloading2','pcaloading3',...
         'signed_pcaloading1','signed_pcaloading2','signed_pcaloading3','pcamaxloading','pcamaxloadingtop'...
         'zy','yz','xz'};
     tracesSorted=sortTypes;
     sortIndex=[];
     return;
 end
 
 if nargin<3
     exclusionList=[];
 end
 
 if nargin<4
     sortParam=[];
 end
 
 if nargin<5
     options=[];
 end
 
 if ~isfield(options,'range')
      options.range=[];
 end
 
 if ~isfield(options,'wbDir')
      options.wbDir=[];
 end
 
 if ~isfield(options,'traceFieldName')
      options.traceFieldName='deltaFOverF';
 end
 
 if ~isfield(options,'refPCAStruct')
      options.refPCAStruct=[];
 end
 
 if ~isfield(options,'refWBStruct')
      options.refWBStruct=[];
 end
 
 
 if isempty(alltraces)
     
     if isempty(options.refWBStruct)
        wbstruct=wbload(options.wbDir,false);
     else
        wbstruct=options.refWBStruct;
     end
     
     alltraces=wbstruct.simple.(options.traceFieldName);
     
 end
 
 exclusionList=unique(exclusionList);  %in case exclusionList has double entries
    
 %remove exclusion list before sorting, will add them back in at the end
 traces=alltraces;
 traces(:,exclusionList)=[];
 
 if ~isempty(options.range)
    traces=traces(options.range,:);
 end
 
 reducedIndex=(1:size(alltraces,2))';
 
 reducedIndex(exclusionList)=[];

 
 numAllTraces=size(alltraces,2);
 numTraces=size(traces,2);
 
 sortVal=zeros(numTraces,1);
    

    switch sortMethod
 
       case {'transition','tta'}
           
           wbstruct=wbload([],'false');
           sortVal=wbEvalTraces(wbload,sortMethod,sortParam);
           %extraAnalysisData=transitionKeyFrame;  %output transitionFrame for plotting
           
       case 'zy' 
       
           wbstruct=wbload([],'false');
           zy=1000*wbstruct.nz'+wbstruct.ny';
           zy(exclusionList)=[];
           sortVal=zy;
           
           
       case 'yz' 
       
           wbstruct=wbload([],'false');
           yz=1000*wbstruct.ny'+wbstruct.nz';
           yz(exclusionList)=[];
           sortVal=yz;
           
       case 'xz' 
       
           wbstruct=wbload([],'false');
           xz=1000*wbstruct.nx'+wbstruct.nz';
           xz(exclusionList)=[];
           sortVal=xz;
           
           
       case 'f0'
       
           wbstruct=wbload([],'false');
           
           if isfield(wbstruct,'f0')
               f0=wbstruct.f0';
               f0(exclusionList)=[];
               sortVal=f0;
           else
               disp('No f0 stored for this dataset.  must have been an old version of wba. rerun.');
           end
           
       case 'corrcluster'
       
          %goodNeuronList=1:numTraces;
          %if isfield(pc,'exclusionList')
          %sortVal(pc.exclusionList)=-Inf;         
          %goodNeuronList(pc.exclusionList)=[];     
        
         %end;
     
         cf=gcf;
         [H,T,sortIndex]=dendrogram(linkage(corrcoef(.000001+fixnan(traces))),size(traces,2));
         close;
         sortIndex=sortIndex(end:-1:1);
         figure(cf);
         
      case 'customcluster'
            
         cf=gcf;
         [H,T,sortIndex]=dendrogram(linkage(.000001+options.customMatrix),size(traces,2));
         close;
         sortIndex=sortIndex(end:-1:1);
         figure(cf);
         
         
      case 'customcluster_transpose'
            
         cf=gcf;
         [H,T,sortIndex]=dendrogram(linkage(.000001+options.customMatrix'),size(traces,2));
         close;
         sortIndex=sortIndex(end:-1:1);
         figure(cf);
         
      case 'covcluster'
         
         cf=gcf;
         [H,T,sortIndex]=dendrogram(linkage(cov(.000001+fixnan(traces))),size(traces,2));
         close;
         sortIndex=sortIndex(end:-1:1);
         figure(cf);
        
         
      case 'covsvd'
        
        conn=cov(.000001+fixnan(traces));
        [U, S, V] = svd(conn);

        iV = zeros(size(traces,2), 2); 
        iU = zeros(size(traces,2), 2); 
        for i=1:2
            u = U(:, i);
            v = V(:, i);
            [~, iV(:, i)] = sort(v, 'descend');
            [~, iU(:, i)] = sort(u, 'descend');
%           sv(i).conn=(conn(iU(:, i), iV(:, i))>0);
        end

        sortIndex=iV(:,1);

        
     case 'customsvd'
        
        conn=options.customMatrix;
        [U, S, V] = svd(conn);

        iV = zeros(size(traces,2), 2); 
        iU = zeros(size(traces,2), 2); 
        for i=1:2
            u = U(:, i);
            v = V(:, i);
            [~, iV(:, i)] = sort(v, 'descend');
            [~, iU(:, i)] = sort(u, 'descend');
%           sv(i).conn=(conn(iU(:, i), iV(:, i))>0);
        end

        sortIndex=iV(:,1);

        

    case 'corrdcluster'  
        
         cf=gcf;
         [H,T,sortIndex]=dendrogram(linkage(corrcoef(.000001+wbDeriv(fixnan(traces)))),size(traces,2));
         sortIndex=sortIndex(end:-1:1);
         figure(cf);
         
    case {'position','none'}
        
        for i=1:numTraces
            sortVal(i)=-i;
        end 
        
    case {'power','rms','RMS'}
        
        traces_zerocenter=detrend(traces,'constant');
        
        for i=1:numTraces
            sortVal(i)=rms(fixnan(traces_zerocenter(:,i)));
        end 
        
    case {'power_detrended','rms_detrended'}  
        
        traces_detrended=detrend(traces,'linear');
        
        for i=1:numTraces  
            sortVal(i)=rms(fixnan(traces_detrended(:,i)));
        end
        
    case {'power_offset','rms_offset','RMS_offset'}
                        
        traces_zerocenter=detrend(traces,'constant');
        
        for i=1:numTraces
            sortVal(i)=rmsOffset(fixnan(traces_zerocenter(:,i)),sortParam);
        end 
        
     case {'power_detrended_offset','rms_offset_detrended'}
                        
        traces_detrended=detrend(traces,'linear');
        
        for i=1:numTraces
            sortVal(i)=rmsOffset(fixnan(traces_detrended(:,i)),sortParam);
        end 
        
        
     case 'power_detrended_offset_rel'
                        
        traces_detrended=detrend(traces,'linear');
        
        for i=1:numTraces
            sortVal(i)=rmsOffset(fixnan(traces_detrended(:,i)),[],'rel');
        end 

        
        
    case 'pcaloading' 

        if ~isempty(sortParam{1})
            n=sortParam{1};
        else
            n=1;
        end
              
        GetWBAndPCAStruct;     

        if isempty(pc) return; end

        if length(sortVal)>length(pc.coeffs(:,sortParam{1}))+length(pc.exclusionList)   %full unexcluded list
            
            goodNeuronList=1:numAllTraces;
            if isfield(wbstruct,'exclusionList')
                sortVal(wbstruct.exclusionList)=-Inf;
                goodNeuronList(wbstruct.exclusionList)=[]; 
            end
            sortVal(goodNeuronList(pc.referenceIndices))=abs(pc.coeffs(:,n));  
        else
            sortVal(:)=-Inf;
            sortVal(pc.referenceIndices)=abs(pc.coeffs(:,n));
        end
        
    case 'pcaloading1' 

        GetWBAndPCAStruct;     

        if isempty(pc) return; end

        if length(sortVal)>length(pc.coeffs(:,1))+length(pc.exclusionList)   %full unexcluded list
            
            goodNeuronList=1:numAllTraces;
%             if isfield(wbstruct,'exclusionList')
%                 sortVal(wbstruct.exclusionList)=-Inf;
%                 goodNeuronList(wbstruct.exclusionList)=[]; 
%             end
            sortVal(goodNeuronList(pc.referenceIndices))=abs(pc.coeffs(:,1));  
        else
            sortVal(:)=-Inf;
            sortVal(pc.referenceIndices)=abs(pc.coeffs(:,1));
        end
        
    case 'pcaloading2'

        GetWBAndPCAStruct;     

        if isempty(pc) return; end

        if length(sortVal)>length(pc.coeffs(:,2))+length(pc.exclusionList)   %full unexcluded list
            
            goodNeuronList=1:numAllTraces;
            if isfield(wbstruct,'exclusionList')
                sortVal(wbstruct.exclusionList)=-Inf;
                goodNeuronList(wbstruct.exclusionList)=[]; 
            end
            sortVal(goodNeuronList(pc.referenceIndices))=abs(pc.coeffs(:,2));  
        else
            sortVal(:)=-Inf;
            sortVal(pc.referenceIndices)=abs(pc.coeffs(:,2));
        end


    case 'pcaloading3'

        GetWBAndPCAStruct;     

        if isempty(pc) return; end

        if length(sortVal)>length(pc.coeffs(:,3))+length(pc.exclusionList)   %full unexcluded list
            
            goodNeuronList=1:numAllTraces;
            if isfield(wbstruct,'exclusionList')
                sortVal(wbstruct.exclusionList)=-Inf;
                goodNeuronList(wbstruct.exclusionList)=[]; 
            end
            sortVal(goodNeuronList(pc.referenceIndices))=abs(pc.coeffs(:,3));  
        else
            sortVal(:)=-Inf;
            sortVal(pc.referenceIndices)=abs(pc.coeffs(:,3));
        end

    case 'signed_pcaloading1'
        
        GetWBAndPCAStruct;     
        
        if isempty(pc) return; end

        if length(sortVal)>length(pc.coeffs(:,1))+length(pc.exclusionList)   %full unexcluded list
            
            goodNeuronList=1:numAllTraces;
%             if isfield(wbstruct,'exclusionList')
%                 sortVal(wbstruct.exclusionList)=-Inf;
%                 goodNeuronList(wbstruct.exclusionList)=[]; 
%             end
            sortVal(goodNeuronList(pc.referenceIndices))=pc.coeffs(:,1);  
        else
            sortVal(:)=-Inf;
            sortVal(pc.referenceIndices)=pc.coeffs(:,1);
        end
        
    
    case 'signed_pcaloading2'  
        
        GetWBAndPCAStruct;     

        if isempty(pc) return; end

        if length(sortVal)>length(pc.coeffs(:,2))+length(pc.exclusionList)   %full unexcluded list
            
            goodNeuronList=1:numAllTraces;
            if isfield(wbstruct,'exclusionList')
                sortVal(wbstruct.exclusionList)=-Inf;
                goodNeuronList(wbstruct.exclusionList)=[]; 
            end
            sortVal(goodNeuronList(pc.referenceIndices))=pc.coeffs(:,2);  
        else
            sortVal(:)=-Inf;
            sortVal(pc.referenceIndices)=pc.coeffs(:,2);
        end


    case 'signed_pcaloading3'  

        GetWBAndPCAStruct;     

        if isempty(pc) return; end

        if length(sortVal)>length(pc.coeffs(:,3))+length(pc.exclusionList)   %full unexcluded list
            
            goodNeuronList=1:numAllTraces;
            if isfield(wbstruct,'exclusionList')
                sortVal(wbstruct.exclusionList)=-Inf;
                goodNeuronList(wbstruct.exclusionList)=[]; 
            end
            sortVal(goodNeuronList(pc.referenceIndices))=pc.coeffs(:,3);  
        else
            sortVal(:)=-Inf;
            sortVal(pc.referenceIndices)=pc.coeffs(:,3);
        end

    case 'pcamaxloading'
       
        GetWBAndPCAStruct;     

        if isempty(pc) return; end


        for i=1:size(pc.coeffs,1)
            [pcMaxLoading(i) pcMembership(i)]=max(abs(pc.coeffs(i,:)));
        end

        
        if length(sortVal)>length(pc.coeffs(:,1))+length(pc.exclusionList)   %full unexcluded list
        
            goodNeuronList=1:numAllTraces;   
            if isfield(wbstruct,'exclusionList')

                sortVal(wbstruct.exclusionList)=-Inf;         
                goodNeuronList(wbstruct.exclusionList)=[];     

            end;

            sortVal(goodNeuronList(pc.referenceIndices))=-(pcMaxLoading+10*pcMembership);   

        else
            sortVal(:)=-Inf;

            sortVal(pc.referenceIndices)=-(pcMaxLoading+10*pcMembership)';    

        end

        
%       disp('highest affinity PC:');
%       sort(pcMembership);

      case 'pcamaxloadingtop'
          
        if isempty(sortParam)
            numTopComps=10;
        else
            numTopComps=sortParam;
        end
        
        GetWBAndPCAStruct;     
                    
        if isempty(pc) return; end

        %assign to PCs
        whichPC=size(pc.coeffs,1);
        
        for j=1:size(pc.coeffs,1)
            [~, whichPC(j)]=max(abs(pc.coeffs(j,1:numTopComps)));
        end
        
        maxCoeff=size(pc.coeffs,1);
        %sort within PC groups
        for k=1:numTopComps
            
             maxCoeff(whichPC==k) = abs(pc.coeffs(whichPC==k,k))+sign(pc.coeffs(whichPC==k,k));
             
        end
        
        
        if length(sortVal)>length(pc.coeffs(:,1))+length(pc.exclusionList)   %full unexcluded list
            
            goodNeuronList=1:numAllTraces;
            sortVal(goodNeuronList(pc.referenceIndices))=maxCoeff(:)+10*(1+numTopComps-whichPC(:));
            
        else
           % sortVal(:)=-Inf;
            sortVal(pc.referenceIndices)=maxCoeff(:)+10*(1+numTopComps-whichPC(:));
            sortValPCneuronsOnly=maxCoeff(:)+10*(1+numTopComps-whichPC(:));

        end

        sortVal=sortValPCneuronsOnly;
        
        extraAnalysisData{1}=whichPC(:).*sign(maxCoeff(:));  %export PC membership
        
        if exist('sortValPCneuronsOnly','var')
            [~,sorting]=sort(sortValPCneuronsOnly,'descend');
            extraAnalysisData{2}= extraAnalysisData{1}(sorting);  %sorted 
        end

      case 'pcamaxloadingtopScaled'

        if isempty(sortParam)
            numTopComps=3;
        else
            numTopComps=sortParam;
        end
        
        GetWBAndPCAStruct;  
        
                    
        if isempty(pc) return; end

        %assign to PCs
        whichPC=size(pc.coeffs,1);
        
        base('pc',pc);
        for j=1:size(pc.coeffs,1)
            
            [~, whichPC(j)]=max((sqrt(pc.varianceExplained(1:numTopComps)')).*abs(pc.coeffs(j,1:numTopComps)));
        end
        
        maxCoeff=size(pc.coeffs,1);
        %sort within PC groups
        for k=1:numTopComps
            
             maxCoeff(whichPC==k) = abs(pc.coeffs(whichPC==k,k))+sign(pc.coeffs(whichPC==k,k));
             
        end
        
        
        if length(sortVal)>length(pc.coeffs(:,1))+length(pc.exclusionList)   %full unexcluded list
            
            goodNeuronList=1:numAllTraces;
            sortVal(goodNeuronList(pc.referenceIndices))=maxCoeff(:)+10*(1+numTopComps-whichPC(:));
            
        else
           % sortVal(:)=-Inf;
            sortVal(pc.referenceIndices)=maxCoeff(:)+10*(1+numTopComps-whichPC(:));
            sortValPCneuronsOnly=maxCoeff(:)+10*(1+numTopComps-whichPC(:));

        end

        sortVal=sortValPCneuronsOnly;
        
        extraAnalysisData{1}=whichPC(:).*sign(maxCoeff(:));  %export PC membership
        
        if exist('sortValPCneuronsOnly','var')
            [~,sorting]=sort(sortValPCneuronsOnly,'descend');
            extraAnalysisData{2}= extraAnalysisData{1}(sorting);  %sorted 
        end
   
        
        
    end
    

    %these sortings already give sortIndex so don't compute from sortVal
    if ~strcmp(sortMethod,'corrcluster') && ~strcmp(sortMethod,'covcluster') && ~strcmp(sortMethod,'covsvd') && ~strcmp(sortMethod,'customcluster') && ~strcmp(sortMethod,'customcluster_transpose')
        [~,sortIndex]=sort(sortVal,1,'descend');
    end
    
    reducedSortIndex=sortIndex;

% max(sortIndex)
% size(reducedIndex)



    %add excluded neurons to the end of the list    
    sortIndex=[reducedIndex(sortIndex) ; exclusionList']; %semi ninja code

    tracesSorted=alltraces(:,sortIndex);

    if ~exist('sortVal','var')  %for sortings that don't give sortVals
        sortVal=sortIndex;
    end
    
    
    
    
    %nested subfunc
            
        function GetWBAndPCAStruct   

        
            if ~isempty(options.refPCAStruct)
                pc=options.refPCAStruct;

            else
                pc=wbLoadPCA(options.wbDir);
            end

            if ~isempty(options.refWBStruct)
                wbstruct=options.refWBStruct;
            else
                wbstruct=wbload(options.wbDir,false);
            end
        
        end

end