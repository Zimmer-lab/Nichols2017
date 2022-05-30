function [transitionIndicesJoint,transitionTimesJoint, traceColoringJoint, transitionIndicesNonJoint, transitionTimesNonJoint, traceColoringNonJoint]=wbGetJointTransitions(wbstructs,refNeuron,transitionTypeRef,neuron1,transitionType1,neuron2,transitionType2,cutoffPre,cutoffPost)

if isempty(wbstructs)
    wbstructs=wbload(pwd,false);
end

if isempty(refNeuron)
    refNeuron='AVAL';
end

if isempty(transitionTypeRef)
    transitionType1='rises';
end

if isempty(neuron1)
    neuron1='AVAL';
end

if isempty(transitionType1)
    transitionType1='rises';
end

if isempty(neuron2)
    neuron2='SMDV';
end

if isempty(transitionType2)
    transitionType2='falls';
end

if isempty(cutoffPre)
    cutoffPre=0; %seconds
end

if isempty(cutoffPost)
    cutoffPost=5; %seconds
end

[traceColoring1,transitions1,runLengths1]=wbGetTransitionsNew(wbstructs,refNeuron,neuron1,transitionTypeRef,transitionType1);
[~,transitions2,~]=wbGetTransitionsNew(wbstructs,refNeuron,neuron2,transitionTypeRef,transitionType2);

for d=1:length(transitions1)
    
    traceColoringJoint{d}=zeros(size(traceColoring1{d}));
    traceColoringNonJoint{d}=zeros(size(traceColoring1{d}));

    fps=wbstructs{d}.fps;
    
    for tr=1:length(transitions1{d})
        
                
        if (transitions2{d}(tr)-transitions1{d}(tr) > -cutoffPre*fps) ...
        && (transitions2{d}(tr)-transitions1{d}(tr) < cutoffPost*fps)
    
            transitionIndicesJoint{d}(tr)=transitions1{d}(tr);
            transitionTimesJoint{d}(tr)=wbstructs{d}.tv(transitions1{d}(tr));
            
            traceColoringJoint{d}(transitions1{d}(tr):transitions1{d}(tr)+runLengths1{d}(tr)-1)=1;
            
            transitionTimesNonJoint{d}(tr)=NaN;
            transitionIndicesNonJoint{d}(tr)=NaN;
            
        else
            
            transitionIndicesJoint{d}(tr)=NaN;
            transitionTimesJoint{d}(tr)=NaN;

            
            transitionIndicesNonJoint{d}(tr)=transitions1{d}(tr);
            transitionTimesNonJoint{d}(tr)=wbstructs{d}.tv(transitions1{d}(tr));
            traceColoringNonJoint{d}(transitions1{d}(tr):transitions1{d}(tr)+runLengths1{d}(tr)-1)=1;

        end
 
    end
    
end

