function wbSave(wbstruct,wbstructFileName)

   if nargin<2
       wbstructFileName=[pwd filesep 'Quant' filesep 'wbstruct.mat'];
   end

   save(wbstructFileName,'-struct','wbstruct');
   
end