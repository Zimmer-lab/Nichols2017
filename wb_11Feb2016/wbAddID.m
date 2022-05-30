function wbAddID(ID,simpleNumber,wbstruct)
%wbAddID(ID,simpleNumber,wbstruct)

if nargin<3 || isempty(wbstruct)
    [wbstruct wbstructFileName]=wbload([],false);
end


wbstruct.simple.ID{simpleNumber}={ID};
wbstruct.simple.ID1{simpleNumber}={ID};

origNumber=wbstruct.simple.nOrig(simpleNumber);
wbstruct.ID{origNumber}={ID};
wbstruct.ID1{origNumber}={ID};

wbSave(wbstruct,wbstructFileName);

end