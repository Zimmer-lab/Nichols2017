function [vafSpectrum,tracesRecon] = wbReconstructDataset(tracesOrWbstructOrWbstructFile,pcsOrPCAstructOrPCAstructFile,options)

if (nargin<3) options=[]; end


if nargin<2 || isempty(pcsOrPCAstructOrPCAstructFile)  
    pcsOrPCAstructOrPCAstructFile=wbLoadPCA([],false);    
elseif ischar(pcsOrPCAstructOrPCAstructFile)    
    pcsOrPCAstructOrPCAstructFile=wbLoadPCA(pcsOrPCAstructOrPCAstructFile,false);    
end

if isstruct(pcsOrPCAstructOrPCAstructFile)    
    pcs=pcsOrPCAstructOrPCAstructFile.pcs;
else    
    pcs=pcsOrPCAstructOrPCAstructFile;    
end



if nargin<1 || isempty(tracesOrWbstructOrWbstructFile)    
   
    traces=pcsOrPCAstructOrPCAstructFile.tracesPreNorm;
        
else
    
    if ischar(tracesOrWbstructOrWbstructFile)
    tracesOrWbstructOrWbstructFile=wbload(tracesOrWbstructOrWbstructFile,false);    
    end
    
    if isstruct(tracesOrWbstructOrWbstructFile)
        traces=detrend(tracesOrWbstructOrWbstructFile.simple.derivs.traces(:,pcsOrPCAstructOrPCAstructFile.referenceIndices),'constant');
    else       
        traces=tracesOrWbstructOrWbstructFile;
    end

end


if ~isfield(options,'numComps')
    options.numComps=size(pcs,2);
end

if ~isfield(options,'plotFlag')  
     options.plotFlag=true;    
end


% base('traces',traces);
% base('pcs',pcs);


% traces=randn(1000,10);
% [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(traces);
% 


%normalize PCs
for i=1:size(pcs,2)
    pcs(:,i)=pcs(:,i)/norm(pcs(:,i));
end

%check orthogonality
% for i=1:size(pcs,2)
%     for j=1:size(pcs,2)
%         
%         ov(i,j)=sum(pcs(:,i).*pcs(:,j))/norm(pcs(:,i))/norm(pcs(:,j));
%         if i==j
%             ov(i,j)=0;
%         end
%     end
% end
% base('ov',ov);


if size(pcs,1) ~= size(traces,1)
    disp('pcs and traces are not the same length. quitting');
    beep(.1);
    return;
end



newCoeff=zeros(size(traces,2),size(pcs,2));
for i=1:size(traces,2)
    for j=1:size(pcs,2)
        newCoeff(i,j)=sum(traces(:,i).*pcs(:,j));
    end
end

%base('newCoeff',newCoeff);


tracesRecon=zeros(size(traces,1),size(traces,2),options.numComps);
vafSpectrum=zeros(1,size(tracesRecon,3));


for k=1:size(tracesRecon,3)
    
    for i=1:size(traces,2)    

        tracesRecon(:,i,k)=detrend((pcs(:,1:k) *  newCoeff(i,1:k)'),'constant');    %% figure out matrix math here
    end

    vafSpectrum(k)=vaf(traces,squeeze(tracesRecon(:,:,k)));
end


if options.plotFlag

    figure;
    for i=1:20
        subtightplot(20,1,i);
        plot(traces(:,i),'b');
        hold on;
        plot(tracesRecon(:,i,size(tracesRecon,3)),'r--');
    end


end


