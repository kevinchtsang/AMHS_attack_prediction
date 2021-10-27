# Asthma Attack Predictions based on AMHS

This repository contains the code that has been used in the study ["Application of Machine Learning to Support Self-Management of Asthma with mHealth"](https://doi.org/10.1109/EMBC44109.2020.9175679)

We used the AMHS dataset to benchmark the ability of four machine learning techniques to predict asthma attacks.

If you would like to use the code, please attribute/cite it to the associated paper or this repository

## Data

Data from the Asthma Mobile Health Study (AMHS) is available at [Synapse](https://www.synapse.org/asthmahealth)

Please do not upload any of the data from AMHS when committing.

This analysis will make use of "Daily Prompt Survey", "Weekly Prompt Survey", and "EQ5D Survey"

## Programming Languages and Libraries

Library | Version 
--- | ---
MATLAB                                            |    Version 9.7         (R2019b)
Simulink                                          |    Version 10.0        (R2019b)
Bioinformatics Toolbox                            |    Version 4.13        (R2019b)
Parallel Computing Toolbox                        |    Version 7.1         (R2019b)
Statistics and Machine Learning Toolbox           |    Version 11.6        (R2019b)
Symbolic Math Toolbox                             |    Version 8.4         (R2019b)

## Getting Started

`Create_` files will create `.mat` files
`Alg_` and `Convert_` files are functions used in the analysis

Please run the files in the following order:
1. `XXX.m` to convert the downloaded CSVs to .mat objects
2. `Create_DailyPromptSurvey_Augmented.m` to add columns based on `get_worse` answers
3. `Create_AllPatients.m` to create `AllPatients` in the workspace
4. `Create_QandA_Lookup.m` defines a dictionary for answers to daily questionnaire
5. `Filter_WeeklyEvents.m` to create the training data
6. `Model_LASSO.m` to rank and select the features
7. `Model_FitModels.m` to benchmark algorithms

## Citation

K. C. H. Tsang, H. Pinnock, A. M. Wilson and S. Ahmar Shah, "Application of Machine Learning to Support Self-Management of Asthma with mHealth," *2020 42nd Annual International Conference of the IEEE Engineering in Medicine & Biology Society (EMBC)*, 2020, pp. 5673-5677, doi: 10.1109/EMBC44109.2020.9175679.
