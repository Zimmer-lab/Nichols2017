function n=wbGetSimpleIndex(neuronString,wbstruct)
%n=wbGetSimpleIndex(neuronString,wbstruct)
%
if nargin<2
    wbstruct=[];
end

[~,~,n]=wbgettrace(neuronString,wbstruct);

end