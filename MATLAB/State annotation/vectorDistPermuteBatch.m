%% vectorDistPermuteBatch
% make sure vector1 and vector2 in vectorDistPermute are commmented out!

clearvars -except RISE1 RISE2 N2RISE1 N2RISE2 N2StateTransQATriggered StateTransQATriggered...
    StateTransTriggered Neurons N2StateTransQATriggered N2RISE1 N2RISE2

vec1 = StateTransQATriggered.ClosestTransArise_Qui2Act_evoked_AVAcorr;
vec2 = StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_AVAcorr;%N2StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_AVAcorr;
vec3 = RISE1;
vec4 = RISE2;

vec5 = N2StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_AVAcorr;
vec6 = N2RISE1;
vec7 = N2RISE2;

vecInputs = {vec1,vec2,vec3,vec4,vec5,vec6,vec7};

count = 1;
for iii = 7;
    for iiii = [3,4];
        if iii == iiii;
        else
            vector1 = vecInputs{iiii};
            vector2 = vecInputs{iii};
            tic
            vectorDistPermute
            toc
            nAbove(count) =sum(vectorDists >= vectorDistsTrue);
            pvaluesAll(count)=double(pValue);
            NeuronsResamAll{count} = NeuronsResam;
            v1EventsAll(count) = v1Events;
            v2EventsAll(count) = v2Events;
            Compared(count,1:2)= [iii,iiii];
            count = count+1;
        end
    end
end
