function options=wbPCADefaultOptions
%options=wbPCADefaultOptions
%set default options for PCA computation.  run this then set more options.

options.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR','ASHR','ASHL'};
options.fieldName='deltaFOverF';
options.dimRedType='PCA';   % or 'OPCA' or 'NMF'
options.useCorrelationsFlag=true; %i.e. use covariance instead
options.preSmoothFlag=false;
options.preSmoothingWindow=10;
options.plotFlag=false;
options.derivFlag=true;
options.derivRegFlag=true;
options.usePrecomputedDerivs=true;
options.integrateDerivComponents=true;

end