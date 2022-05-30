function  [F2FMat,R2RMat,MT2MTMat]=wbGetTransitionRanges(transitionListCellArray)
%
%

    %four cases to handle
    %(1)  FRFRF       
    %(2)  FRFR   
    %(3)  RFRFR
    %(4)  RFRF
    %
    %assumes alternating rise/fall transitions
    
    %
    % 
    
    
    transitionsRise=transitionListCellArray{1};
    %transitionsRise=sort([transitionListCellArray{1},transitionListCellArray{6},transitionListCellArray{8}]);
    transitionsPlateau=transitionListCellArray{2};
    transitionsFall=transitionListCellArray{4};
    transitionsTrough=transitionListCellArray{5};
    
    
    %compute F2F and R2R Ranges
    F2FRange=[];
    R2RRange=[];
    MT2MTRange=[];
    
    
    %add all valid ranges
    for i=1:length(transitionsFall)-1
        F2FRange(i,:)=[transitionsFall(i) transitionsFall(i+1)];
    end
    
    for i=1:length(transitionsRise)-1
        R2RRange(i,:)=[transitionsRise(i) transitionsRise(i+1)];
    end
    
    %add incomplete ranges depending on the cases listed above
    
    if transitionsFall(1)<transitionsRise(1)        
        R2RRange=[1 transitionsRise(1); R2RRange];  %case 1,2  %eliminating Nans
    else
        
        F2FRange=[1 transitionsFall(1); F2FRange];  %case 3,4  %eliminating Nans
    end
       
    
    if transitionsFall(end)<transitionsRise(end)        
        F2FRange=[F2FRange; NaN NaN];  %case 2,3           
    else
        R2RRange=[R2RRange; NaN NaN];  %case 1,4
    end
    
    
    %compute MT2MT Ranges 

    if transitionsRise(1)<transitionsTrough(1)
       transitionsRiseFollowing=transitionsRise(2:end);
    else
       transitionsRiseFollowing=transitionsRise; 
    end
    
    if transitionsRiseFollowing(end)<transitionsTrough(end)
        transitionsTroughLeading=transitionsTrough(1:end-1);
    else
        transitionsTroughLeading=transitionsTrough;
    end

   
    
    
    for i=1:length(transitionsTroughLeading)-1
       MT2MTRange(i,:)=([(transitionsTroughLeading(i)+transitionsRiseFollowing(i))/2 (transitionsTroughLeading(i+1)+transitionsRiseFollowing(i+1))/2 ]);
    end
    
    
    %compute R2RMat
    transitionsPlateauScrubbed=zeros(size(R2RRange,1),1);
    transitionsFallScrubbed=zeros(size(R2RRange,1),1);
    transitionsTroughScrubbed=zeros(size(R2RRange,1),1);

    for ii=1:size(R2RRange,1)

        nv=find(transitionsPlateau>R2RRange(ii,1) & transitionsPlateau < R2RRange(ii,2),1);
        if isempty(nv)
            transitionsPlateauScrubbed(ii)=R2RRange(ii,1)+1;    
        else
            transitionsPlateauScrubbed(ii)=transitionsPlateau(nv);
        end

        nv=find(transitionsTrough>R2RRange(ii,1) & transitionsTrough < R2RRange(ii,2),1);
        if isempty(nv)
           transitionsTroughScrubbed(ii)=R2RRange(ii,2)-1;
        else
           transitionsTroughScrubbed(ii)=transitionsTrough(nv);
        end

        nv=find(transitionsFall>transitionsPlateauScrubbed(ii) & transitionsFall< transitionsTroughScrubbed(ii),1);
        if isempty(nv)
           transitionsFallScrubbed(ii)=transitionsTroughScrubbed(ii)-1;
        else
           transitionsFallScrubbed(ii)=transitionsFall(nv) ;
        end

    end
        
    R2RMat=[R2RRange(:,1), transitionsPlateauScrubbed, transitionsFallScrubbed ,transitionsTroughScrubbed , R2RRange(:,2)];
        

    %compute F2FMat

    transitionsTroughScrubbed=zeros(size(F2FRange,1),1);
    transitionsRiseScrubbed=zeros(size(F2FRange,1),1);
    transitionsPlateauScrubbed=zeros(size(F2FRange,1),1);
    
    
    for ii=1:size(F2FRange,1)

        nv=find(transitionsTrough>F2FRange(ii,1) & transitionsTrough < F2FRange(ii,2),1);
        if isempty(nv)
            transitionsTroughScrubbed(ii)=F2FRange(ii,1)+1;    
        else
            transitionsTroughScrubbed(ii)=transitionsTrough(nv);
        end

        nv=find(transitionsPlateau>F2FRange(ii,1) & transitionsPlateau < F2FRange(ii,2),1);
        if isempty(nv)
           transitionsPlateauScrubbed(ii)=F2FRange(ii,2)-1;
        else
           transitionsPlateauScrubbed(ii)=transitionsPlateau(nv);
        end

        nv=find(transitionsRise>transitionsTroughScrubbed(ii) & transitionsRise < transitionsPlateauScrubbed(ii),1);
        if isempty(nv)
           transitionsRiseScrubbed(ii)=transitionsPlateauScrubbed(ii)-1;
        else
           transitionsRiseScrubbed(ii)=transitionsRise(nv) ;
        end

    end
    
 
    F2FMat=[F2FRange(:,1), transitionsTroughScrubbed ,transitionsRiseScrubbed , transitionsPlateauScrubbed, F2FRange(:,2)];


    
    %compute MT2MTMat (mid trough to mid trough)

    MT2MTMat=[];

    
    transitionsTroughScrubbed=zeros(size(MT2MTRange,1),1);
    transitionsRiseScrubbed=zeros(size(MT2MTRange,1),1);
    transitionsPlateauScrubbed=zeros(size(MT2MTRange,1),1);
    transitionsFallScrubbed=zeros(size(MT2MTRange,1),1);
    
    
    for ii=1:size(MT2MTRange,1)

        nv=find(transitionsRise>MT2MTRange(ii,1) & transitionsRise < MT2MTRange(ii,2),1);
        if isempty(nv)
            transitionsRiseScrubbed(ii)=MT2MTRange(ii,1)+1;    
        else
            transitionsRiseScrubbed(ii)=transitionsRise(nv);
        end

        nv=find(transitionsTrough>transitionsRiseScrubbed(ii) & transitionsTrough < MT2MTRange(ii,2),1);
        if isempty(nv)
           transitionsTroughScrubbed(ii)=MT2MTRange(ii,2)-1;
        else
           transitionsTroughScrubbed(ii)=transitionsTrough(nv);     
        
        nv=find(transitionsFall>transitionsRiseScrubbed(ii) & transitionsFall < transitionsTroughScrubbed(ii),1);
        if isempty(nv)
           transitionsFallScrubbed(ii)=transitionsTroughScrubbed(ii)-1;
        else
           transitionsFallScrubbed(ii)=transitionsFall(nv);
        end

        nv=find(transitionsPlateau>transitionsRiseScrubbed(ii) & transitionsPlateau < transitionsFallScrubbed(ii),1);
        if isempty(nv)
           transitionsPlateauScrubbed(ii)=transitionsFallScrubbed(ii)-1;
        else
           transitionsPlateauScrubbed(ii)=transitionsPlateau(nv) ;
        end

    end
    
 
    MT2MTMat=[MT2MTRange(:,1),transitionsRiseScrubbed , transitionsPlateauScrubbed, transitionsFallScrubbed, transitionsTroughScrubbed, MT2MTRange(:,2)];
    
    
end