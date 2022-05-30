function pValue=SigTest(testType,D,opt)
%
%D.numPts
%D.empDist
%D.acceptLevel
%D.sampleSize

if nargin<3
    opt=[];
end

if ~isfield(opt,'plotFlag')
    opt.plotFlag=false;
end

if ~isfield(opt,'numSamples')
    opt.numSamples=100000;
end

if ~isfield(opt,'testStatisticFunction')
    opt.testStatisticFunction=@mean;
end

if nargin<1
    testType='bootstrap';
end

if strcmp(testType,'SingleProb')
    
    
    if nargin<2 || isempty(D)

        D.numPts=100;
        D.refProportion=0.4;
        D.measuredProportion=0.4;

    end
    
    
else %bootstrap
    
%     D.empDist=randn(100,1);
%     D.sampleSize=1;
%     D.acceptLevel=.9;
    
    
end


if strcmp(testType,'SingleProb')



    %significance testing by bootstrap

    


    sample=nan(opt.numSamples,1);

    for i=1:opt.numSamples


        sample(i)=sum(rand(D.numPts,1)<D.refProportion);

    end

    pValue=1-sum(sample<(D.measuredProportion*D.numPts))/opt.numSamples;


    if opt.plotFlag

        %figure;
        hist(sample,0:D.numPts);
        hold on;
        vline(D.measuredProportion*D.numPts);
        intitle(['p=' num2str(pValue) ', n=' num2str(D.numPts)]);
        xlim([0 D.numPts]);

    end


elseif strcmp(testType,'permutation')
    
    D.empDistN=numel(D.empDist);
        
    D.sampleSize;
    sample=nan(1,opt.numSamples);
    for i=1:opt.numSamples
        
          rp=randperm(D.empDistN,D.sampleSize);
          
          
          sample(i)=  opt.testStatisticFunction(D.empDist(rp));
        
          
          
    end
    
    if D.acceptLevel<opt.testStatisticFunction(D.empDist)
        pValue=sum(sample<=D.acceptLevel)/opt.numSamples;
    else
        pValue=sum(sample>=D.acceptLevel)/opt.numSamples;
    end
    
    if opt.plotFlag
        
        %figure;
        hist(sample,100);
        hold on;
        vline(D.acceptLevel);
        intitle(['p=' num2str(pValue) ', nsamples=' num2str(opt.numSamples)]);

    end
    
elseif strcmp(testType,'eventBins')
    
    D.numBins;
    sample=nan(1,opt.numSamples);
 
    for i=1:opt.numSamples
        
        
        %place in
    
    end
    
    pValue=sum(sample>=D.acceptLevel)/opt.numSamples;

    if opt.plotFlag
        
        %figure;
        hist(sample,100);
        hold on;
        vline(D.acceptLevel);
        intitle(['p=' num2str(pValue) ', nsamples=' num2str(opt.numSamples)]);

    end
    
else %bootstrap
    
    D.empDistN=numel(D.empDist);
    
    
    D.sampleSize;
    sample=nan(1,opt.numSamples);
    for i=1:opt.numSamples
        
          rp=randi(D.empDistN,1,D.sampleSize);
                  
          sample(i)=opt.testStatisticFunction(D.empDist(rp));
        
          
          
    end
    
    pValue=sum(sample>D.acceptLevel)/opt.numSamples;
    
    if opt.plotFlag
        
        %figure;
        hist(sample,100);
        hold on;
        vline(D.acceptLevel);
        intitle(['p=' num2str(pValue) ', nsamples=' num2str(opt.numSamples)]);

    end
    
    
    
    
end

