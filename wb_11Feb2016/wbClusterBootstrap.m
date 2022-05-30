function stats=wbClusterBootstrap(clusterStruct,options)

    if nargin<2
        options=[];
    end
    
    if ~isfield(options,'bootstrapFlag') 
        options.bootstrapFlag=true;
    end 
    
    if ~isfield(options,'bootstrapNumIterations')
        options.bootstrapNumIterations=100000;
    end 
    
    if ~isfield(options,'bootstrapSequentialDrawFlag')
        options.bootstrapSequentialDrawFlag=false;
    end 
    
    if ~isfield(options,'plotFlag')
        options.plotFlag=true;
    end
    
    if ~isfield(options,'altBootstrapInputValues')
        options.altBootstrapInputValues=[];
    end
    
    if ~isfield(options,'altBootstrapDistanceMeasure')
        options.altBootstrapDistanceMeasure=[];
    end
    
    if ~isfield(options,'altBootstrapNan')
        options.altBootstrapNan=[];
    end

    if nargin<1 || isempty(clusterStruct)
        clusterStruct=load([pwd filesep 'Quant' filesep 'wbClusterStruct.mat']);
    end

    if isempty(options.altBootstrapInputValues)
        
        inputValues=clusterStruct.inputValues;
        distanceMeasure=clusterStruct.options.distanceMeasure;
        
    else  %alt bootstrapping
        
        inputValues=options.altBootstrapInputValues;
        
        %skip nan elements
        
        if ndims(inputValues)==3
            inputValues(:,:,options.altBootstrapNan)=[];
        else
            inputValues(:,options.altBootstrapNan)=[];
        end
        nanItems=find(options.altBootstrapNan);
        
        clusterStruct.clusterMembership(options.altBootstrapNan)=[];
        
        for cn=1:numel(clusterStruct.clusterIndices)
            clusterStruct.clusterIndices{cn}=find(clusterStruct.clusterMembership==cn);
        end

        
        if isempty(options.altBootstrapDistanceMeasure)
            distanceMeasure=clusterStruct.options.distanceMeasure;
        else
            distanceMeasure=options.altBootstrapDistanceMeasure;
        end
         
    end

    

    numPts=size(inputValues,ndims(inputValues)); %get last dimension
    dist=zeros(numPts);

    
    
    %compute full pairwise distance matrix    
    if ndims(inputValues)==3
        for i=1:numPts
            for j=1:i-1
                dist(i,j)=computeDistance(inputValues(:,:,i),inputValues(:,:,j),distanceMeasure);
                dist(j,i)=dist(i,j);
            end
        end
    else
        for i=1:numPts
            for j=1:i-1
                dist(i,j)=computeDistance(inputValues(:,i),inputValues(:,j),distanceMeasure);
                dist(j,i)=dist(i,j);
            end
        end
    end
      

    %average intracluster distance
    for cn=1:numel(clusterStruct.clusterIndices)
        k=1;
        for i=1:length(clusterStruct.clusterIndices{cn})
            for j=1:i-1
                stats.distIntra{cn}(k)=dist(clusterStruct.clusterIndices{cn}(i),clusterStruct.clusterIndices{cn}(j));
                k=k+1;
            end
        end
        stats.distIntra_numPairs(cn)=length(clusterStruct.clusterIndices{cn})*(length(clusterStruct.clusterIndices{cn})-1)/2;
        stats.distIntra_mean(cn)=mean(stats.distIntra{cn});

        if stats.distIntra_numPairs(cn)>0
            stats.distIntra_sem(cn)=std(stats.distIntra{cn})/sqrt(stats.distIntra_numPairs(cn));
        else
            stats.distIntra_sem(cn)=0;
        end

    end

    %average intracluster distance
    for cn=1:numel(clusterStruct.clusterIndices)
        k=1;
        for i=1:length(clusterStruct.clusterIndices{cn})
            for j=1:i-1
                stats.distIntra{cn}(k)=dist(clusterStruct.clusterIndices{cn}(i),clusterStruct.clusterIndices{cn}(j));
                k=k+1;
            end
        end
        stats.distIntra_numPairs(cn)=length(clusterStruct.clusterIndices{cn})*(length(clusterStruct.clusterIndices{cn})-1)/2;
        stats.distIntra_mean(cn)=mean(stats.distIntra{cn});

        if stats.distIntra_numPairs(cn)>0
            stats.distIntra_sem(cn)=std(stats.distIntra{cn})/sqrt(stats.distIntra_numPairs(cn));
        else
            stats.distIntra_sem(cn)=0;
        end

    end
    
    
    
    %intercluster distance assume 2 clusters for now
    distInterSub=dist(clusterStruct.clusterIndices{1},clusterStruct.clusterIndices{2});
    stats.distInter=distInterSub(:);
    
    stats.distInter_numPairs(1)=length(clusterStruct.clusterIndices{1})*length(clusterStruct.clusterIndices{2});
    stats.distInter_mean(1)=mean(stats.distInter);

    if stats.distInter_numPairs(1)>0
        stats.distInter_sem(1)=std(stats.distInter)/sqrt(stats.distInter_numPairs(1));
    else
        stats.distInter_sem(1)=0;
    end


    stats.distRatio=mean(stats.distInter_mean)/mean(stats.distIntra_mean);


    
    %bootstrap

    if options.bootstrapFlag
        
        disp('wbClusterState> bootstrapping...');
        tic;

        numPts_c(1)=length(clusterStruct.clusterIndices{1});
        numPts_c(2)=length(clusterStruct.clusterIndices{2});
        
        for cn=1:2
            diagnan{cn}=diag(nan(numPts_c(cn),1));
        end
            
        
        if options.bootstrapNumIterations==-1  %exhaustive
            options.bootstrapNumIterations=nchoosek(numPts,numPts_c(1));  
        end
        
        
        if options.bootstrapSequentialDrawFlag    %ordered permutation    
            
            nextchoose_func=nextchoose(numPts,numPts_c(1));

            for n=1:options.bootstrapNumIterations
            
                RP=nextchoose_func();
                
                numPtsInd=1:numPts;
                RP_Not=numPtsInd;
                RP_Not(RP)=[];
                
                %intra               
                distSubMat=dist(RP,RP)+diagnan{1};
                temp.distIntra_mean(1)=nanmean(distSubMat(:));
               
                distSubMat=dist(RP_Not,RP_Not)+diagnan{2};
                temp.distIntra_mean(2)=nanmean(distSubMat(:));
               

                %inter
                distInterSub=dist(RP,RP_Not);
                temp.distInter=distInterSub(:);

                %ratio
                stats.bootstrapRatioDist(n)=mean(temp.distInter)/mean(temp.distIntra_mean);

                if mod(n,100000)==1 disp(num2str(n)); end
            end
                
            
        else  %random draws
        

            for n=1:options.bootstrapNumIterations

                RP=randperm(numPts);

                drawPts{1}=RP(1:numPts_c(1));
                drawPts{2}=RP(numPts_c(1)+1:end);            

                %intra
                for cn=1:2
                    distSubMat=dist(drawPts{cn},drawPts{cn})+diagnan{cn};
                    temp.distIntra_mean(cn)=nanmean(distSubMat(:));
                end


                %inter
                distInterSub=dist(drawPts{1},drawPts{2});
                temp.distInter=distInterSub(:);

                %ratio
                stats.bootstrapRatioDist(n)=mean(temp.distInter)/mean(temp.distIntra_mean);

            end

        end
    
    
        %compute p-value
        stats.pValue=numel(find(stats.bootstrapRatioDist>stats.distRatio))/length(stats.bootstrapRatioDist);
      
        if options.plotFlag
            figure;
            hist(stats.bootstrapRatioDist,100)
            hold on;
            vline(stats.distRatio);
            textur(['p-value=' num2str(stats.pValue)]);
        end

        toc;
        
    end
    
    stats.dist=dist;
    stats.lastRP=RP; %for debugging purposes

function dist=computeDistance(v1,v2,distanceMeasure)
    
    %if v's are 2D then time series should be column vectors
    if ndims(v1)==1
        v1=v1(:)'; %force row
        v2=v2(:)';
    end
    base('v1',v1)
    if strcmpi(distanceMeasure,'cityblock')

        dist=mean(sum(abs(v1-v2),2));
        
    elseif strcmpi(distanceMeasure,'euclidean')
        
        dist=mean(sqrt(sum((v1-v2).^2,2)));
        
    end
end


end