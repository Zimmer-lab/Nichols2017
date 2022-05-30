function [PCMstruct,PCAiStruct]=wbComputePCLassoMatch(folder1,folder2,options)

if nargin<3
    options=[];
end

if ~isfield(options,'plotFlag')
    options.plotFlag=false;
end

if ~isfield(options,'numPCs')
    options.numPCs=10;
end

if ~isfield(options,'lassoLambdaIndex')
    options.lassoLambdaIndex=50;  %from 1 to 100
end


if ~isfield(options,'lassoDFMax')
    options.lassoDFMax=[];
end

if ~isfield(options,'lassoAlpha')
    options.lassoAlpha=1;  %from 1 to 100
end

if ~isfield(options,'neuronSubsetOverride')
    options.neuronSubsetOverride=[];
end

computePCAoptions=wbPCADefaultOptions;
computePCAoptions.plotFlag=false;
computePCAoptions.neuronSubset=options.neuronSubsetOverride;

PCAiStruct=ForEachFolder({folder1,folder2},@wbComputePCA,{[],computePCAoptions});

PCMstruct.B1=zeros(options.numPCs,options.numPCs,100);
PCMstruct.B2=zeros(options.numPCs,options.numPCs,100);

for pc=1:options.numPCs
%     X=detrend(zeronan(PCAiStruct.PCAi{1}.coeffs(:,1:options.numPCs)),'constant');
% 
%     Y=detrend(zeronan(PCAiStruct.PCAi{2}.coeffs(:,pc)),'constant');
%     [tmp,PCMstruct.S1(pc)]=lasso(X,Y,'Alpha',options.lassoAlpha);
%     PCMstruct.B1(:,pc,1:size(tmp,2))=tmp;
    
    X2=detrend(zeronan(PCAiStruct{2}.coeffs(:,1:options.numPCs)),'constant');

    Y2=detrend(zeronan(PCAiStruct{1}.coeffs(:,pc)),'constant');

    [tmp,PCMstruct.S2(pc)]=lasso(X2,Y2,'Alpha',options.lassoAlpha);
    PCMstruct.B2(:,pc,1:size(tmp,2))=tmp;
    
    cum=zeros(size(PCAiStruct{2}.coeffs,1),1);
    for j=1:options.numPCs

        cum=cum+(PCMstruct.B2(j,pc,options.lassoLambdaIndex))*PCAiStruct{2}.coeffs(:,j);
    end
    
    PCMstruct.coeffs_matched(:,pc)=cum;
    
    
    thiscc=corrcoef(PCAiStruct{1}.coeffs(:,pc),PCMstruct.coeffs_matched(:,pc));
    PCMstruct.cc(pc)=thiscc(2,1);
end
    
    
%recompute de-mixed temporal PCs
for i=1:options.numPCs
    cum=zeros(size(PCAiStruct{2}.pcs,1),1);
    for j=1:options.numPCs
        cum=cum+(PCMstruct.B2(j,i,options.lassoLambdaIndex))*PCAiStruct{2}.pcs(:,j);
    end
    PCMstruct.pcs_matched(:,i)=cum;
end




                  
end

