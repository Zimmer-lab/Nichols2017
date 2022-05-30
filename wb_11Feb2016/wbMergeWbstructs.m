function wbMergeWbstructs(parentFolder)

if nargin<1
    parentFolder=pwd;
end

wbstruct=wbload(parentFolder);  %loads all subfolder wbstructs

wbstructMerge.simple.dateMergeRan=datestr(now);

wbstructMerge.simple.x=[];
wbstructMerge.simple.y=[];
wbstructMerge.simple.z=[];
wbstructMerge.simple.region=[];
wbstructMerge.simple.deltaFOverF=[];
wbstructMerge.simple.nOrig=[];

wbstructMerge.simple.stimulus=wbstruct{1}.simple.stimulus;
wbstructMerge.simple.tv=wbstruct{1}.simple.tv;

wbstructMerge.simple.nn=0;
wbstructMerge.simple.f0=[];
wbstructMerge.simple.ID=[];
wbstructMerge.simple.ID1=[];
wbstructMerge.simple.ID2=[];
wbstructMerge.simple.ID3=[];

wbstructMerge.simple.deltaFOverF_bc=[];
wbstructMerge.simple.deltaFOverF_bc_suppData.tau=[];
wbstructMerge.simple.deltaFOverF_bc_suppData.bleachcurves=[];
wbstructMerge.simple.deltaFOverF_bc_options=wbstruct{1}.simple.deltaFOverF_bc_options;



for i=1:length(wbstruct)
    
    wbstructMerge.simple.x=[wbstructMerge.simple.x  wbstruct{i}.simple.x];
    wbstructMerge.simple.y=[wbstructMerge.simple.y  wbstruct{i}.simple.y];
    wbstructMerge.simple.z=[wbstructMerge.simple.z  wbstruct{i}.simple.z];
    
    wbstructMerge.simple.region=[wbstructMerge.simple.region; i*ones(wbstruct{i}.simple.nn,1)];    
    wbstructMerge.simple.deltaFOverF=[wbstructMerge.simple.deltaFOverF wbstruct{i}.simple.deltaFOverF];    
    wbstructMerge.simple.nOrig=[wbstructMerge.simple.nOrig wbstruct{i}.simple.nOrig ];
    
    wbstructMerge.simple.nn=wbstructMerge.simple.nn + wbstruct{i}.simple.nn;
    
    
    wbstructMerge.simple.f0=[wbstructMerge.simple.f0  wbstruct{i}.simple.f0];
       
    wbstructMerge.simple.ID=[wbstructMerge.simple.ID wbstruct{i}.simple.ID];
    wbstructMerge.simple.ID1=[wbstructMerge.simple.ID1 wbstruct{i}.simple.ID1];
    wbstructMerge.simple.ID2=[wbstructMerge.simple.ID2 wbstruct{i}.simple.ID2];
    wbstructMerge.simple.ID3=[wbstructMerge.simple.ID3 wbstruct{i}.simple.ID3];

    wbstructMerge.simple.deltaFOverF_bc=[wbstructMerge.simple.deltaFOverF_bc wbstruct{i}.simple.deltaFOverF_bc];
    wbstructMerge.simple.deltaFOverF_bc_suppData.tau=[wbstructMerge.simple.deltaFOverF_bc_suppData.tau wbstruct{i}.simple.deltaFOverF_bc_suppData.tau];
    wbstructMerge.simple.deltaFOverF_bc_suppData.bleachcurves=[wbstructMerge.simple.deltaFOverF_bc_suppData.bleachcurves wbstruct{i}.simple.deltaFOverF_bc_suppData.bleachcurves];
end

mkdir('Quant')
save('Quant/wbstruct.mat','-struct','wbstructMerge');

disp('wbMergeWbstructs> wbstructs merged.');

end