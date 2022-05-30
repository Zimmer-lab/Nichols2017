%function wbComputeManifoldDistribution(wbPCAstruct,options)
%compute distributions of bundle diameter and tangent vector divergence
%
%

%preliminaries

% if nargin<1 || isempty(wbPCAStruct)
%     
wbPCAStruct{1}=wbLoadPCA([],false);
wbstruct{1}=wbload([],false);
 
% if nargin<2
%     options=[];
% end
% 

pcs=wbPCAStruct{1}.pcs;

numFrames=size(pcs,1);
canonicalTimesReg=[0 .25 0.5 0.75 1.0]; 
canonicalTimesT2T=[0 0.125 0.375 0.625 0.875 1.0]; 
canonicalTimes=canonicalTimesReg;

numDatasets=1;
options.refNeuron='AVAL';

%compute timewarped TWFrames and TWFallFrames for each transition period of each dataset
for d=1:numDatasets
    
    tv{d}=wbstruct{d}.tv;
    
    %load transition data
    [traceColoring{d}, transitionListCellArray{d},transitionPreRunLengthArray{d}]=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',options.refNeuron);
    [F2FMat{d},R2RMat{d},MT2MTMat{d}]=wbGetTransitionRanges(transitionListCellArray{d});
    transitionsRise{d}=(wbGetTransitions(transitionListCellArray{d},1,'SignedAllRises',[],transitionPreRunLengthArray{d}))';
    transitionsFall{d}=(wbGetTransitions(transitionListCellArray{d},1,'SignedAllFalls',[],transitionPreRunLengthArray{d}))';
    transitionsRiseMat{d}=F2FMat{d};
    transitionsFallMat{d}=R2RMat{d};
    transitionsT2TMat{d}=MT2MTMat{d};

    %load unsmoothed trajs
    trajDataX{d}=pcs(:,1);
    trajDataY{d}=pcs(:,2);
    trajDataZ{d}=pcs(:,3);       
    
    TWRiseFrames{d}=zeros(length(tv{d}),size(transitionsRiseMat{d},1));
    for k=1:size(transitionsRiseMat{d},1)               
        TWRiseFrames{d}(:,k)=interp1(canonicalTimesReg*length(tv{d}),transitionsRiseMat{d}(k,:)-0.5,0:(length(tv{d})-1),'linear');
    end

    TWFallFrames{d}=zeros(length(tv{d}),size(transitionsFallMat{d},1));
    for k=1:size(transitionsFallMat{d},1)              
        TWFallFrames{d}(:,k)=interp1(canonicalTimesReg*length(tv{d}),transitionsFallMat{d}(k,:)-0.5,0:(length(tv{d})-1),'linear');
    end

    TWT2TFrames{d}=zeros(length(tv{d}),size(transitionsT2TMat{d},1));

    for k=1:size(transitionsT2TMat{d},1)              
        TWT2TFrames{d}(:,k)=interp1(canonicalTimesT2T*length(tv{d}),transitionsT2TMat{d}(k,:)-0.5,0:(length(tv{d})-1),'linear');
    end

end

%interpolate trajectory positions and color           
for d=1:numDatasets

         for k=1:size(transitionsRiseMat{d},1)  

              mTrajRiseDataX{d}(:,k)=interp1(1:length(tv{d}),trajDataX{d},TWRiseFrames{d}(:,k));         
              mTrajRiseDataY{d}(:,k)=interp1(1:length(tv{d}),trajDataY{d},TWRiseFrames{d}(:,k));   
              mTrajRiseDataZ{d}(:,k)=interp1(1:length(tv{d}),trajDataZ{d},TWRiseFrames{d}(:,k));   
              
%               if isempty(timeColoring{d})
%                   thisTimeColoring=ones(length(tv{d}),1);
%               else
%                   thisTimeColoring=timeColoring{d};
%               end
% 
%               mTrajRiseDataC{d}(:,k)=interp1(1:length(tv{d}),thisTimeColoring,TWRiseFrames{d}(:,k),'nearest');

         end

         %compute mean rise trajectory
         meanTrajRiseDataX{d}=nanmean(mTrajRiseDataX{d},2);
         meanTrajRiseDataY{d}=nanmean(mTrajRiseDataY{d},2);
         meanTrajRiseDataZ{d}=nanmean(mTrajRiseDataZ{d},2);
         %meanTrajRiseDataC{d}=mode(mTrajRiseDataC{d},2); 

         for k=1:size(transitionsFallMat{d},1)   

              mTrajFallDataX{d}(:,k)=interp1(1:length(tv{d}),trajDataX{d},TWFallFrames{d}(:,k));         
              mTrajFallDataY{d}(:,k)=interp1(1:length(tv{d}),trajDataY{d},TWFallFrames{d}(:,k));   
              mTrajFallDataZ{d}(:,k)=interp1(1:length(tv{d}),trajDataZ{d},TWFallFrames{d}(:,k));   
              %mTrajFallDataC{d}(:,k)=interp1(1:length(tv{d}),thisTimeColoring,TWFallFrames{d}(:,k),'nearest');
         end

         %compute mean fall trajectory
         meanTrajFallDataX{d}=nanmean(mTrajFallDataX{d},2);
         meanTrajFallDataY{d}=nanmean(mTrajFallDataY{d},2);
         meanTrajFallDataZ{d}=nanmean(mTrajFallDataZ{d},2);
         %meanTrajFallDataC{d}=mode(mTrajFallDataC{d},2); 


         for k=1:size(transitionsT2TMat{d},1)   

              mTrajT2TDataX{d}(:,k)=interp1(1:length(tv{d}),trajDataX{d},TWT2TFrames{d}(:,k));         
              mTrajT2TDataY{d}(:,k)=interp1(1:length(tv{d}),trajDataY{d},TWT2TFrames{d}(:,k));   
              mTrajT2TDataZ{d}(:,k)=interp1(1:length(tv{d}),trajDataZ{d},TWT2TFrames{d}(:,k));   
              %mTrajT2TDataC{d}(:,k)=interp1(1:length(tv{d}),thisTimeColoring,TWT2TFrames{d}(:,k),'nearest');
         end

end


%% Global measurements
T=size(pcs,1);
dist3=zeros(T);


%compute mean pairwise distance of full dataset

for t2=1:T
    for t1=1:(t2-1)
                dist3(t1,t2)= norm ( pcs(t1,1:3) - pcs(t2,1:3) );
    end
end

dist3_nozeros=dist3(dist3>0);

mean(dist3_nozeros(:))
figure;
hist(dist3_nozeros(:),100);


%% compute diameter of time warp slices

numSlices=100;
frameStep=floor(numFrames/numSlices);

meanDiameter=zeros(numSlices,1);
d=1;

for i=1:numSlices 
    
    fr=frameStep*i;
    
    %pts=getTimeWarpPoints(timeWarp(i));
    
    pts=[mTrajFallDataX{d}(fr,:)' mTrajFallDataY{d}(fr,:)' mTrajFallDataZ{d}(fr,:)'];
    
    numPts=size(pts,1);
    thisDist3=zeros(numPts);
    for p2=1:numPts
        for p1=1:p2-1
            thisDist3(p1,p2)=norm(pts(p1 ,:)  - pts(p2,:));
        end
    end
    thisDist3=thisDist3(:);
    thisDist3=thisDist3(thisDist3>0);
    meanDiameter(i)=mean(thisDist3(:));
end

figure;plot(meanDiameter);
vline([ numSlices/4 numSlices/2 3*numSlices/4]);

%%
for i=1:numSlices 
    
    fr=frameStep*i;
    
    %pts=getTimeWarpPoints(timeWarp(i));
    
    pts=[mTrajRiseDataX{d}(fr,:)' mTrajRiseDataY{d}(fr,:)' mTrajRiseDataZ{d}(fr,:)'];
    
    numPts=size(pts,1);
    thisDist3=zeros(numPts);
    for p2=1:numPts
        for p1=1:p2-1
            thisDist3(p1,p2)=norm(pts(p1 ,:)  - pts(p2,:));
        end
    end
    thisDist3=thisDist3(:);
    thisDist3=thisDist3(thisDist3>0);
    meanDiameter(i)=mean(thisDist3(:));
end

figure;plot(meanDiameter);

%%



%end
   