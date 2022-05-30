function timeColoring = wbgettimecoloring(wbstruct,neuronString,traceFunctionHandle,functionParams)
%wbgettimecoloring = wbgettimecoloring(wbstruct,neuronString,traceFunctionHandle)
%
%provide a coloring scheme based on the operation of a functoin on a neural
%trace
%

trace = wbgettrace(neuronString,wbstruct);

if nargin<4
    timeColoring = traceFunctionHandle(trace);
else
    timeColoring = traceFunctionHandle(trace,functionParams);
end

end