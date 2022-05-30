function handles=KillHandle(handleNameString,handles,index,subindex)
%gracefully wipe a graphics handle or array of handles or cell array of
%handle vectors
%
%handleName is a string, handles is a struct of handles.
%something weird going on with array access, don't use for now


    if isfield(handles,handleNameString)
        if ~isempty(handles.(handleNameString))
            
            
            if iscell(handles.(handleNameString))
                
                if nargin<3 || isempty(index)
                    index=1:length(handles.(handleNameString));
                end              
                               
                for i=index
                    
                    if nargin<4 || isempty(subindex)
                        subindex=1:length(handles.(handleNameString){i});
                    end
                        
                    for j=subindex
                        
                        if ishghandle(handles.(handleNameString){i}(j)) && handles.(handleNameString){i}(j)>0
                            delete(handles.(handleNameString){i}(j));
                        end
                    end

                    
                end
                
                
                
            else
                
                if nargin<3 || isempty(index)
                    index=1:length(handles.(handleNameString));
                end  
                
                for i=index
                    if i<=length(handles.(handleNameString)) && ishghandle(handles.(handleNameString)(i)) && handles.(handleNameString)(i)>0
                        delete(handles.(handleNameString)(i));
                    end
                end

            end
            
            
            handles.(handleNameString)=[];
        end
    end

end