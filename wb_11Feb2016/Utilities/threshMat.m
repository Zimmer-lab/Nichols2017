function outMat=threshMat(inMat,thresh)
size(thresh)
    outMat=inMat.*heaviside(inMat-thresh);
end
