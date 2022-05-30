function [TTARiseStruct,TTAFallStruct]=wbComputeTTAFullMatrixBoth

tic
options.transitionTypes='SignedAllRises';
TTARiseStruct=wbComputeTTAFullMatrix([],options);
toc

tic
options.transitionTypes='SignedAllFalls';
TTAFallStruct=wbComputeTTAFullMatrix([],options);
toc

end