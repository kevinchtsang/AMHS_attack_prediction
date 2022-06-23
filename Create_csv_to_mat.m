clc;clear all;

% read csv and return .mat object

%% Read Daily_Prompt and Weekly_Prompt 

% rename files downloaded from Synapse as 
% DailyPrompt.csv
% WeeklyPrompt.csv


%% Read DailyPrompt.csv
%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 15);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["ROW_ID", "ROW_VERSION", "recordId", "healthCode", "createdOn", "appVersion", "phoneInfo", "medicine", "medicine_change", "day_symptoms", "night_symptoms", "use_qr", "quick_relief_puffs", "get_worse", "peakflow"];
opts.VariableTypes = ["double", "double", "string", "categorical", "double", "categorical", "double", "double", "categorical", "categorical", "categorical", "categorical", "double", "string", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["recordId", "get_worse"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["recordId", "healthCode", "appVersion", "medicine_change", "day_symptoms", "night_symptoms", "use_qr", "get_worse"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "phoneInfo", "TrimNonNumeric", true);
opts = setvaropts(opts, "phoneInfo", "ThousandsSeparator", ",");

% Import the data
DailyPromptSurvey = readtable("./data/DailyPrompt.csv", opts);


%% Clear temporary variables
clear opts

save("DailyPromptSurvey.mat", "DailyPromptSurvey");

%% Read WeeklyPrompt.csv
%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 16);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["ROW_ID", "ROW_VERSION", "recordId", "healthCode", "createdOn", "appVersion", "phoneInfo", "asthma_doc_visit", "asthma_medicine", "oral_steroids", "prednisone", "emergency_room", "admission", "limitations", "missed_work", "side_effects"];
opts.VariableTypes = ["double", "double", "string", "categorical", "double", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "recordId", "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["recordId", "healthCode", "appVersion", "phoneInfo", "asthma_doc_visit", "asthma_medicine", "oral_steroids", "prednisone", "emergency_room", "admission", "limitations", "missed_work"], "EmptyFieldRule", "auto");

% Import the data
WeeklyPromptSurvey = readtable("./data/WeeklyPrompt.csv", opts);


%% Clear temporary variables
clear opts

save("WeeklyPromptSurvey.mat", "WeeklyPromptSurvey");