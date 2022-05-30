function [trace, neuronNumber, simpleNeuronNumber] = wbgettraceOLD(neuronString,wbstruct,fieldName,useOnlyPrimaryIDFlag,verboseFlag)
% [trace, neuronNumber, simpleNeuronNumber] = wbgettrace(neuronString,wbstruct,fieldName,useOnlyPrimaryIDFlag,verboseFlag)

    if nargin<5 || isempty(verboseFlag)
        verboseFlag=true;
    end
    

    if nargin<4 || isempty(useOnlyPrimaryIDFlag)
        useOnlyPrimaryIDFlag=true;
    end
    
    if nargin<3 || isempty(fieldName)
        fieldName='deltaFOverF';
    end

    if nargin<2 || isempty(wbstruct)
        wbstruct=wbload([],'false');
    end
    
    if ischar(neuronString)
        
        neuronString=upper(neuronString); %make uppercase
    
        if ~isfield(wbstruct,'ID')

            disp('wbgettrace> error: no ID field in wbstruct.')
            trace=NaN;
            neuronNumber=NaN;
            return;

        end

        traceCount=0;
        for n=1:length(wbstruct.ID)

            IDtemp=wbstruct.ID{n};
            
            if ~isempty(IDtemp)
                


                if useOnlyPrimaryIDFlag
                    j=sum(find(strcmp(neuronString,IDtemp{1})));
                else
                    j=sum(find(strcmp(neuronString,IDtemp)));
                end


                if j
                    i=n;
                    jlast=j;  %if we want to track the label priority in the future
                    traceCount=traceCount+1;
                end

            end
        end
        
        
        %get simple neuron number
        i2=NaN;
        if isfield(wbstruct,'simple')

            %backward compatibility
            if ~isfield(wbstruct.simple,'ID')
                wbMakeSimpleStruct;
                wbstruct=wbload([],false);
            end
            
            for n2=1:length(wbstruct.simple.ID)

                IDtemp=wbstruct.simple.ID{n2};  %one row
                
                if ~isempty(IDtemp)
                    

                    if useOnlyPrimaryIDFlag
                        j=sum(find(strcmp(neuronString,IDtemp{1})));
                    else
                        j=sum(find(strcmp(neuronString,IDtemp)));
                    end


                    if j
                        i2=n2;
                        jlast=j;  %if we want to track the label priority in the future
                    end
                
                end
            end
        end

        if traceCount==0
            if verboseFlag
                disp(['wbgettrace> error: no neuron ' neuronString ' found.']);
            end
            trace=NaN;
            neuronNumber=NaN;
            simpleNeuronNumber=i2;

            return;
    %     elseif traceCount > 1
    %         disp(['too many ' neuronString 's found. check wbstruct.ID for duplicates.']);
    %         trace=NaN;
    %         neuronNumber=NaN;
    %         return;
        else
            traces=wbstruct.(fieldName);
            neuronNumber=i;   
            simpleNeuronNumber=i2;
            trace=traces(:,i);
        end

    else
        
        neuronNumber=neuronString;
        simpleNeuronNumber=neuronString;  %not right, should change
        traces=wbstruct.(fieldName);
        trace=traces(:,neuronNumber);
        
    end
end