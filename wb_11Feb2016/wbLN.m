function lnstruct=wbLN(wbstructOrTraces,inNum,outNum,options)
%lnstruct=wbLN(wbstruct,inNum,outNum,options)
%wb wrapper for lnest
%

if nargin<4
    options=[];
end

%options
if ~isfield(options,'makePlotFlag')
    options.makePlotFlag=0;
end

if ~isfield(options,'forceCausalFlag');
    options.forceCausalFlag=false;
end

%lnest9 free params
hlen=50;
svdlength=50;
range=0;
iter=1;
estmethod=1;
nltype='poly5';
derivflag=0;
hlen2=50;
detrendtype='constant';

if options.forceCausalFlag
    hlen2=[];
end

fieldName='deltaFOverF';

if isstruct(wbstructOrTraces)
    inp=wbstructOrTraces.simple.(fieldName)(:,inNum);
    outp=wbstructOrTraces.simple.(fieldName)(:,outNum);
else
    inp=wbstructOrTraces(:,inNum);
    
    outp=wbstructOrTraces(:,outNum);
end

lnstruct=lnest9(inp,outp,hlen,svdlength,range,estmethod,options,detrendtype,nltype,hlen2,iter,derivflag);

end