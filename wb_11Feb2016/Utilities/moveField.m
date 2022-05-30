function struct=moveField(struct,fieldname,destination)


fieldNames=fieldnames(struct);
fieldNum=find(strcmp(fieldNames,fieldname));


perm=1:length(fieldNames);

perm(fieldNum)=[];

if strcmp(destination,'top')
    perm=[fieldNum perm];
elseif strcmp(destination,'bottom')
    perm=[perm fieldNum];
else
    perm=[perm(1:destination-1) fieldNum  perm(destination:end)];
end

struct=orderfields(struct,perm);

end



  