function matrixOut=wbComputeRelationMatrix(wbstructOrTraces,relation,options,relationParams)
%matrixOut=wbComputeRelationMatrix(traces,relation,options)
%
%compute a pairwise relation matrix for a set of traces
%

if (nargin<1) wbstructOrTraces=wbload([],false); end
if (nargin<2) relation='lnfit'; end  %'corr'
if (nargin<3) options=[]; end
if (nargin<4) relationParams=[]; end

if ~isfield(options,'useOnlyIDedNeurons')
    options.useOnlyIDedNeurons=false;
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset=[];
end

%request all supported types
if ischar(wbstructOrTraces)  
    
    matrixOut={'corr','cov','lnfit','lncausalfit','tta'};
    return;
end

%parse wbstructOrTraces
if isstruct(wbstructOrTraces)
    
    if ~isfield(options,'fieldName')
        options.fieldName='deltaFOverF';
    end
     
    if isempty(options.neuronSubset)
       traces=wbGetTraces(wbstructOrTraces,options.useOnlyIDedNeurons,options.fieldName);
    else
       traces=wbGetTraces(wbstructOrTraces,options.useOnlyIDedNeurons,options.fieldName,options.neuronSubset);
    end
else
    traces=wbstructOrTraces;
end

numTraces=size(traces,2);

relation=lower(relation); %make relation lowercase

switch relation

    case {'corr','corrcoef','correlation'}
    
        matrixOut=corrcoef(traces);

    case {'cov','covariance'}
        
        matrixOut=cov(traces);
        
    case {'corrd','corrderiv','correlationderivative'}
        
        matrixOut=corrcoef( wbDeriv(traces));
        
    case {'lnfit'}
        
        disp('computing pairwise ln models.');
        
        matrixOut=zeros(numTraces);
         
        reverseStr=[];      
        for n1=1:numTraces
            for n2=1:numTraces
          
                lnstruct12=wbLN(traces,n1,n2);
                matrixOut(n1,n2)=lnstruct12.vaf2.*heaviside(lnstruct12.vaf2);

            end
            
            %display progress
            msg=sprintf('%d/%d ',n1,numTraces);
            fprintf([reverseStr msg]);
            reverseStr = repmat(sprintf('\b'), 1, length(msg));
        end
      
        
        fprintf('\n');
        
    case {'lncausalfit'}

            disp('computing pairwise causal ln models.');

            matrixOut=zeros(numTraces);

            wbLNoptions.forceCausalFlag=true;

            reverseStr=[];      
            for n1=1:numTraces
                for n2=1:numTraces

                    lnstruct12=wbLN(traces,n1,n2,wbLNoptions);
                    matrixOut(n1,n2)=lnstruct12.vaf2.*heaviside(lnstruct12.vaf2);

                end

                %display progress
                msg=sprintf('%d/%d ',n1,numTraces);
                fprintf([reverseStr msg]);
                reverseStr = repmat(sprintf('\b'), 1, length(msg));
            end


            fprintf('\n');
            
    case {'tta'}
        
        if isempty(relationParams)
            relationParams{1}=5;
        end
        
        disp('wbComputeRelationMatrix> computing TTA.');
        options.saveData=false;
        
        wbTTAstruct=wbComputeTTAFullMatrix(wbstructOrTraces,options);
        matrixOut=wbTTAstruct.delayMeanMatrix;
        matrixOut(matrixOut<0)=NaN;
        matrixOut(wbTTAstruct.delayStDevMatrix>relationParams{1})=NaN;
        
           
    otherwise

        matrixOut=zeros(numTraces);    

        
end