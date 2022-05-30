function [PPCAStruct, PCMStruct, PCAiStruct,cc]=wbComparePCAAllPairs(folders,options)
%[PPCAStruct, PCMStruct, PCAiStruct,cc]=wbComparePCAAllPairs(rootFolder,options)

flagstr=[];
globalNeuronNames=LoadGlobalNeuronIDs;

if nargin<1
    folders=listfolders(pwd);
    
end

if nargin<2
    options=[];
end

if ~isfield(options,'lassoLambdaIndex')
    options.lassoLambdaIndex=1;  %from 1 to 100
end

if ~isfield(options,'lassoAlpha')
    options.lassoAlpha=1;  %from 1 to 100
end

if ~isfield(options,'lassoDFMax')
    options.lassoDFMax=[]; 
end


if ~isfield(options,'lassoMatchFlag')
    options.matchPCsFlag=true;
    flagstr=[flagstr '-lassomatch'];
    flagstr=[flagstr '-lambda' num2str(options.lassoLambdaIndex)]; 
end

if ~isfield(options,'numPCs')
    options.numPCs=10;
end

if ~isfield(options,'plotFlag')
    options.plotFlag=false;
end

if ~isfield(options,'neuronSubsetOverride')
    options.neuronSubsetOverride=[]; 
end

if ~options.lassoMatchFlag
    PCMStruct=[];
    PCAiStruct=[];
else
    PPCAStruct=[];
end



%PPCAStruct(i,j).neuronSubset=options.neuronSubsetOverride;
cc=zeros(length(folders),length(folders),1);

for i=1:length(folders)
    for j=[1:(i-1) i+1:length(folders)]  %skip main diagonal i=j
        disp([num2str(i) ',' num2str(j)]);
        
        if options.lassoMatchFlag %demix
            [PCMStruct(i,j),PCAiStruct(i,j)]=wbComputePCLassoMatch(folders{i},folders{j},options);
            cc(i,j,1:length(PCMStruct(i,j).cc))=PCMStruct(i,j).cc;

        else
            if j>i%just regs
            PPCAStruct(i,j)=wbComparePCAPairwise(folders{i},folders{j},options);
            cc(i,j,1:length(PPCAStruct(i,j).cc))=PPCAStruct(i,j).cc;
            else
                PPCAStruct(i,j)=PPCAStruct(j,i);
                cc(i,j,:)=cc(j,i,:);

            end
        end
        
    end
end

%% average pc coeffs from each trial


%% plots

if options.plotFlag
    
    wbPlotPCACorrelations(cc,flagstr);
    
end


end