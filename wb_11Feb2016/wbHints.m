function wbhints=wbHints()

    try
        wbhints=load(['Quant' filesep 'wbhints.mat']);
    catch me
        disp('wbHints> no Quant/wbhints.mat file found.  using defaults.');
        
        wbhints.stateRefNeuron='AVAL';
    end
end