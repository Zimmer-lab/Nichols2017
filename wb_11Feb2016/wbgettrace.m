function [trace, neuronNumber, simpleNeuronNumber,f0,fullNeuronString] = wbgettrace(neuronString,wbstruct,fieldName,useOnlyPrimaryIDFlag,verboseFlag,forceSingleTraceFlag)
% [trace, neuronNumber, simpleNeuronNumber] = wbgettrace(neuronString,wbstruct,fieldName,useOnlyPrimaryIDFlag,verboseFlag)

    if nargin<6 || isempty(forceSingleTraceFlag)
        forceSingleTraceFlag=true;
    end
    
    if nargin<5 || isempty(verboseFlag)
        verboseFlag=false;
    end
    
    if nargin<4 || isempty(useOnlyPrimaryIDFlag)
        useOnlyPrimaryIDFlag=true;
    end
    
    if nargin<3 || isempty(fieldName)
        fieldName='deltaFOverF_bc';
    end

    if nargin<2 || isempty(wbstruct)
        [wbstruct, wbstructFileName]=wbload([],'false');
    end
    
    if ischar(neuronString)
        
        neuronString=upper(neuronString); %make uppercase
    
        if ~isfield(wbstruct,'ID')

            disp('wbgettrace> error: no ID field in wbstruct.')
            trace=NaN;
            neuronNumber=NaN;
            return;

        end

        if ~isfield(wbstruct,'ID1')
            wbstruct=wbMakeSimpleStruct(wbstructFileName);  %will call wbUpdateOldStruct if necessary
        end
        
        if useOnlyPrimaryIDFlag
   
            neuronNumber=find(strncmpi(wbstruct.ID1,neuronString,length(neuronString)));
        else
            neuronNumber=find(strncmpi(wbstruct.ID1,neuronString,length(neuronString)) & strncmpi(wbstruct.ID2,neuronString,length(neuronString)) & strncmpi(wbstruct.ID3,neuronString,length(neuronString)));
        end
        
        if forceSingleTraceFlag && ~isempty(neuronNumber)
                neuronNumber=neuronNumber(1);
        end

        if ~isfield(wbstruct,'simple')

            %backward compatibility
            if ~isfield(wbstruct.simple,'ID')
                wbMakeSimpleStruct;
                wbstruct=wbload([],false);
            end
            
        end
        
        %get simple neuron number

        %backward compatibility
        if ~isfield(wbstruct.simple,'ID1')
            wbMakeSimpleStruct;
            wbstruct=wbload([],false);
        end


        if useOnlyPrimaryIDFlag
            simpleNeuronNumber=find(strncmpi(wbstruct.simple.ID1,neuronString,length(neuronString)));
        else
            simpleNeuronNumber=find(strncmpi(wbstruct.simple.ID1,neuronString,length(neuronString)) & strncmpi(wbstruct.simple.ID2,neuronString,length(neuronString)) & strncmpi(wbstruct.simple.ID3,neuronString,length(neuronString)));
        end
  
        if forceSingleTraceFlag && ~isempty(simpleNeuronNumber)
            simpleNeuronNumber=simpleNeuronNumber(1);
        end
        
        %check for string-typed simpleNumber
        if isempty(neuronNumber)
            
            if strcmpi(num2str(str2num(neuronString)),neuronString)
                simpleNeuronNumber=str2num(neuronString);
                neuronNumber=wbstruct.simple.nOrig(simpleNeuronNumber);
            end
        end      
        
        
        if isempty(neuronNumber)
            if verboseFlag
                disp(['wbgettrace> error: no neuron ' neuronString ' found.']);
            end
            trace=NaN;
            neuronNumber=NaN;
            simpleNeuronNumber=NaN;
            f0=NaN;
            fullNeuronString='';

            return;

        else
            
            if iscell(fieldName) && numel(fieldName)==2
                trace=wbstruct.simple.(fieldName{1}).(fieldName{2})(:,simpleNeuronNumber);
            else               
                trace=wbstruct.(fieldName)(:,neuronNumber);
            end
            
            if isfield(wbstruct,'f0')
                f0=wbstruct.f0(neuronNumber);
            else
                f0=NaN;
            end
	        
            if length(neuronNumber)==1
                fullNeuronString=wbstruct.ID1{neuronNumber};
            else
                fullNeuronString=wbstruct.ID1(neuronNumber);
            end

        end


    else %numerical input
        
        neuronNumber=neuronString;
        simpleNeuronNumber=neuronString;  %not right, should change
        if  iscell(fieldName) && numel(fieldName)==2
            trace=wbstruct.simple.(fieldName{1}).(fieldName{2})(:,SimpleNeuronNumber);               
        else
            trace=wbstruct.(fieldName)(:,neuronNumber);
        end
        if isfield(wbstruct,'f0')
            f0=wbstruct.f0;
            f0=f0(:,neuronNumber);
        else
            f0=[];
        end
        fullNeuronString=wbstruct.ID1{neuronNumber};
    end
end