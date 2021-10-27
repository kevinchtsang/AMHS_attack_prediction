%% Daily Prompt answer look up
% Create look up for full answers in daily prompt questionnaire

% get_worse = Did any of the following cause your asthma to get worse today? (check all that apply):
keySet = 1:22;
valueSet = ["A cold"; 
    "Exercise"; 
    "Being more active than usual (walking, running, climbing stairs)"; 
    "Strong smells (perfume, chemicals, sprays, paint)"; 
    "Exhaust fumes"; "House dust"; "Dogs"; "Cats"; 
    "Other furry/feathered animals"; "Mold"; "Pollen from trees, grass or weeds"; 
    "Extreme heat"; "Extreme cold"; "Changes in weather"; "Around the time of my period"; 
    "Poor air quality"; "Someone smoking near me"; "Stress"; 
    "Feeling sad, angry, excited, tense"; "Laughter";
    "I don't know what triggers my asthma"; "None of these things trigger my asthma"];

DailyPrompt_lookup_get_worse = containers.Map(keySet,valueSet);

% medicine = Did you take your asthma control medicine in the last 24 hours?
keySet = 1:4;
valueSet = ["Yes, all of my prescribed doses"; "Yes, some but not all of my prescribed doses";
    "No, I did not take them"; "I'm not sure"];
DailyPrompt_lookup_medicine = containers.Map(keySet,valueSet);

save('QandA_Lookup.mat','DailyPrompt_lookup_get_worse','DailyPrompt_lookup_medicine')

