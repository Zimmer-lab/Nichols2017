
wbload;


endrange=900:1000;
method='XX';
startrange=1:100;
fminfac=0.9;
coop=0;
[wbstruct.deltaFOverF_bc,tau,bleachcurves] = bleachcorrect(wbstruct.deltaFOverF,endrange,method,coop,startrange,fminfac);
wbstruct.deltaFOverF_bc=wbstruct.deltaFOverF_bc-1;
%wbstruct.deltaFOverF_bc=detrend(wbstruct.deltaFOverF,'linear');

gpoptions.fieldName='deltaFOverF_bc';



wbgridplot(wbstruct,gpoptions);


save('wbstruct.mat','wbstruct');