function wbNMFstruct=wbComputeNMF(wbstructOrFolder,numComps,options)

if nargin<2 || isempty(numComps)
    numComps=20;
end

options.numComps=numComps;
options.dimRedType='NMF';
wbNMFstruct=wbComputePCA(wbstructOrFolder,options);

end