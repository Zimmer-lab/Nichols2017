    function [nIDs, nClasses]=LoadGlobalNeuronIDs()
    
    nIDs={...
    'ADAL','ADAR',...
    'ADEL','ADER',...
    'ADFL','ADFR',...
    'ADLL','ADLR',...
    'AFDL','AFDR',...
    'AIAL','AIAR',...
    'AIBL','AIBR',...
    'AIML','AIMR',...
    'AINL','AINR',...
    'AIYL','AIYR',...
    'AIZL','AIZR',...
    'ALA',...
    'ALML','ALMR',...
    'ALNL','ALNR',...
    'AQR',...
    'AS01','AS02','AS03','AS04','AS05','AS06',...
    'AS07','AS08','AS09','AS10','AS11',...
    'ASEL','ASER',...
    'ASGL','ASGR',...
    'ASHL','ASHR',...
    'ASIL','ASIR',...
    'ASJL','ASJR',...
    'ASKL','ASKR',...
    'AUAL','AUAR',...
    'AVAL','AVAR',...
    'AVBL','AVBR',...
    'AVDL','AVDR',...
    'AVEL','AVER',...
    'AVFL','AVFR',...
    'AVG',...
    'AVHL','AVHR',...
    'AVJL','AVJR',...
    'AVKL','AVKR',...
    'AVL',...
    'AVM',...
    'AWAL','AWAR',...
    'AWBL','AWBR',...
    'AWCL','AWCR',...
    'BAGL','BAGR',...
    'BDUL','BDUR',...
    'CANL','CANR',...
    'CEPDL','CEPDR',...
    'CEPVL','CEPVR',...
    'DA01','DA02','DA03','DA04','DA05',...
    'DA06','DA07','DA08','DA09',...
    'DB01',...
    'DB02',...
    'DB03',...
    'DB04',...
    'DB05',...
    'DB06',...
    'DB07',...
    'DD01','DD02','DD03','DD04','DD05','DD06',...
    'DVA',...
    'DVB',...
    'DVC',...
    'FLPL','FLPR',...
    'HSNL','HSNR',...
    'IL1DL','IL1DR',...
    'IL1L','IL1R',...
    'IL1VL','IL1VR',...
    'IL2DL','IL2DR',...
    'IL2L','IL2R',...
    'IL2VL','IL2VR',...
    'LUAL','LUAR',...
    'OLLL','OLLR',...
    'OLQDL','OLQDR',...
    'OLQVL','OLQVR',...
    'PDA',...
    'PDB',...
    'PDEL','PDER',...
    'PHAL','PHAR',...
    'PHBL','PHBR',...
    'PHCL','PHCR',...
    'PLML','PLMR',...
    'PLNL','PLNR',...
    'PQR',...
    'PVCL','PVCR',...
    'PVDL','PVDR',...
    'PVM',...
    'PVNL','PVNR',...
    'PVPL','PVPR',...
    'PVQL','PVQR',...
    'PVR',...
    'PVT',...
    'PVWL','PVWR',...
    'RIAL','RIAR',...
    'RIBL','RIBR',...
    'RICL','RICR',...
    'RID',...
    'RIFL','RIFR',...
    'RIGL','RIGR'...
    'RIH',...
    'RIML','RIMR',...
    'RIPL','RIPR',...
    'RIR',...
    'RIS',...
    'RIVL','RIVR',...
    'RMDDL','RMDDR',...
    'RMDL','RMDR',...
    'RMDVL','RMDVR',...
    'RMED',...
    'RMEL','RMER',...
    'RMEV',...
    'RMFL','RMFR',...
    'RMGL','RMGR',...
    'RMHL','RMHR',...
    'SAADL','SAADR',...
    'SAAVL','SAAVR',...
    'SABD',...
    'SABVL','SABVR'...
    'SDQL','SDQR',...
    'SIADL','SIADR'....
    'SIAVL','SIAVR',...
    'SIBDL','SIBDR',...
    'SIBVL','SIBVR',...
    'SMBDL','SMBDR',...
    'SMBVL','SMBVR',...
    'SMDDL','SMDDR',...
    'SMDVL','SMDVR',...
    'URADL','URADR',...
    'URAVL','URAVR',...
    'URBL','URBR',...
    'URXL','URXR',...
    'URYDL','URYDR',...
    'URYVL','URYVR',...
    'VA01',...
    'VA02',...
    'VA03',...
    'VA04',...
    'VA05',...
    'VA06',...
    'VA07',...
    'VA08',...
    'VA09',...
    'VA10',...
    'VA11',...
    'VA12',...
    'VB01',...
    'VB02',...
    'VB03',...
    'VB04',...
    'VB05',...
    'VB06',...
    'VB07',...
    'VB08',...
    'VB09',...
    'VB10',...
    'VB11',...
    'VC01',...
    'VC02',...
    'VC03',...
    'VC04',...
    'VC05',...
    'VC06',...
    'VD01',...
    'VD02',...
    'VD03',...
    'VD04',...
    'VD05',...
    'VD06',...
    'VD07',...
    'VD08',...
    'VD09',...
    'VD10',...
    'VD11',...
    'VD12',...
    'VD13',...
    'I1L','I1R'...
    'I2L','I2R'...
    'I3','I4','I5','I6',...
    'M1',...
    'M2L','M2R',...
    'M3L','M3R',...
    'M4',...
    'M5',...
    'MI',...
    'MCL','MCR',...
    'NSML','NSMR',...
    }';
    
    nClasses={...
    'ADA'...
    'ADE',...
    'ADF',...
    'ADL',...
    'AFD',...
    'AIA',...
    'AIB',...
    'AIM',...
    'AIN',...
    'AIY',...
    'AIZ',...
    'ALA',...
    'ALM',...
    'ALN',...
    'AQR',...
    'AS',...
    'ASE',...
    'ASG',...
    'ASH',...
    'ASI',...
    'ASJ',...
    'ASK',...
    'AUA',...
    'AVA',...
    'AVB',...
    'AVD',...
    'AVE',...
    'AVF',...
    'AVG',...
    'AVH',...
    'AVJ',...
    'AVK',...
    'AVL',...
    'AVM',...
    'AWA',...
    'AWB',...
    'AWC',...
    'BAG',...
    'BDU',...
    'CAN',...
    'CEP',...
    'DA',...
    'DB',...
    'DD',...
    'DVA',...
    'DVB',...
    'DVC',...
    'FLP',...
    'HSN',...
    'IL1',...
    'IL2',...
    'LUA',...
    'OLL',...
    'OLQ',...
    'PDA',...
    'PDB',...
    'PDE',...
    'PHA',...
    'PHB',...
    'PHC',...
    'PLM',...
    'PLN',...
    'PQR',...
    'PVC',...
    'PVD',...
    'PVM',...
    'PVN',...
    'PVP',...
    'PVQ',...
    'PVR',...
    'PVT',...
    'PVW',...
    'RIA',...
    'RIB',...
    'RIC',...
    'RID',...
    'RIF',...
    'RIG'...
    'RIH',...
    'RIM',...
    'RIP',...
    'RIR',...
    'RIS',...
    'RIV',...
    'RMD',...
    'RME',...
    'RMF',...
    'RMG',...
    'RMH',...
    'SAA',...
    'SAB',...
    'SDQ',...
    'SIA',...
    'SIB',...
    'SMB',...
    'SMD',...
    'URA',...
    'URB',...
    'URX',...
    'URY',...
    'VA',...
    'VB',...
    'VC',...
    'VD',...
    'I1',...
    'I2',...
    'I3','I4','I5','I6',...
    'M1',...
    'M2',...
    'M3',...
    'M4',...
    'M5',...
    'MI',...
    'MC',...
    'NSM',...
    }';   
    end
