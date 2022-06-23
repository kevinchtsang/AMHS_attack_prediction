# Asthma Attack Predictions based on AMHS

This repository contains the code that has been used in the study ["Application of Machine Learning to Support Self-Management of Asthma with mHealth" (Tsang et al., 2020)](https://doi.org/10.1109/EMBC44109.2020.9175679) 

We used the AMHS dataset to benchmark the ability of four machine learning techniques to predict asthma attacks.

If you would like to use the code, please attribute/cite it to the associated paper or this repository (see Citation below).

## Abstract
While there have been several efforts to use mHealth technologies to support asthma management, none so far offer personalised algorithms that can provide real-time feedback and tailored advice to patients based on their monitoring. This work employed a publicly available mHealth dataset, the Asthma Mobile Health Study (AMHS), and applied machine learning techniques to develop early warning algorithms to enhance asthma self-management. The AMHS consisted of longitudinal data from 5,875 patients, including 13,614 weekly surveys and 75,795 daily surveys. We applied several well-known supervised learning algorithms (classification) to differentiate stable and unstable periods and found that both logistic regression and naïve Bayes-based classifiers provided high accuracy (AUC > 0.87). We found features related to the use of quick-relief puffs, night symptoms, frequency of data entry, and day symptoms (in descending order of importance) as the most useful features to detect early evidence of loss of control. We found no additional value of using peak flow readings to improve population level early warning algorithms.

## Data

Data from the Asthma Mobile Health Study (AMHS) is available at [Synapse](https://www.synapse.org/asthmahealth)

Please do not upload any of the data from AMHS when committing, including CSVs and any Matlab objects with data.

This analysis will make use of "Daily Prompt Survey" and "Weekly Prompt Survey"

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

`Create_` files will create `.mat` files.

`Alg_` and `Convert_` files are functions used in the analysis.

First, download the AMHS data as CSVs and put them in the `data` folder. Then rename the files to `DailyPrompt.csv` and `WeeklyPrompt.csv` accordingly.

Please run the files in the following order:
1. `Create_csv_to_mat.m` to convert the downloaded CSVs to `.mat` objects
2. `Create_DailyPromptSurvey_Augmented.m` to add columns based on `get_worse` answers
3. `Create_AllPatients.m` to create `AllPatients` in the workspace
4. `Create_QandA_Lookup.m` defines a dictionary for answers to daily questionnaire
5. `Filter_WeeklyEvents.m` to create the training data
6. `Model_LASSO.m` to rank and select the features
7. `Model_FitModels.m` to benchmark algorithms

## Citation

K. C. H. Tsang, H. Pinnock, A. M. Wilson and S. Ahmar Shah, "Application of Machine Learning to Support Self-Management of Asthma with mHealth," *2020 42nd Annual International Conference of the IEEE Engineering in Medicine & Biology Society (EMBC)*, 2020, pp. 5673-5677, doi: 10.1109/EMBC44109.2020.9175679.
