function wbRemoveField(folder,field)
%wbRemoveField(folder,field)

if nargin<2
    field='added';
    disp('wbRemoveField> no field specified.  Using <added> field.');
end

if nargin<1 || isempty(folder)
    folder=pwd;
end
    
[wbstruct,wbstructFileName]=wbload(folder,[]);

if isfield (wbstruct,field)
    wbstruct=rmfield(wbstruct,field);
    wbSave(wbstruct,wbstructFileName);
else
    disp(['wbRemoveField> field <' field '> does not exist.  doing nothing.']);
end

    
end