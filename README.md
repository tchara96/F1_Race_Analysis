# 🏁 F1 Performance Analytics Ecosystem

A comprehensive collection of data engineering and analytics projects focused on Formula 1 performance. This repository tracks my progression from historical data management to building automated, high-frequency telemetry analysis pipelines.

---

## 📂 Project Portfolio

### [01 | F1 Race Data Analysis](./01_F1_Race_Data_Analysis)
**Focus:** Historical Data & Global Statistics  
* Initial exploration of the F1 technical ecosystem.
* Management of core categorical data and race status tracking (e.g., `status.csv`).
* Analysis of historical trends and race result distributions.

### [02 | F1 Post-Race Analysis](./02_F1_Post_Race_Analysis)
**Focus:** Session Breakdowns & Championship Impact  
* Detailed investigation of specific race weekend outcomes.
* Visualization of driver performance delta and point distributions.
* Automated reporting logic for post-event evaluation.

### [03 | F1 Practice Pace Analysis](./03_F1_Practice_Pace_Analysis)
**Focus:** Predictive Modeling & Friday Pace  
* Scripts designed to analyze Free Practice (FP) data.
* Early modeling of race pace vs. qualifying trim to predict weekend hierarchies.
* Processing of high-frequency timing data to identify "sandbagging" vs. true performance.

### [04 | F1 2026 Pre-Season Testing Analysis](./04_F1_PreSeason_Testing_Analysis_2026)
**Focus:** Automated Multi-Day Pipeline & Regulation Simulation  
* **Dynamic Metadata Ingestion:** A MATLAB-based engine that automatically parses CSV headers to identify active driver lineups.
* **Degradation Modeling:** Advanced linear regression analysis to calculate tire wear coefficients ($s/lap$) across 6 days of testing.
* **Master Aggregator:** A unified pipeline (`post_analysis_v4.m`) that synthesizes 144 hours of raw data into a "Global Source of Truth."
* **Reliability Audit:** Longitudinal tracking of team workload and cumulative mileage progression.



---

## 🛠️ Technical Stack & Skills
* **Primary Language:** MATLAB
* **Data Science:** Linear Regression, Data Normalization, Predictive Modeling.
* **Data Engineering:** Dynamic File Parsing, Automated Multi-sheet Excel Generation, Metadata Extraction.
* **Tools:** Git, Excel (Reporting), TracingInsights (Source Data).

---

## 🚀 Getting Started

To explore the findings or run the analysis pipelines:

1.  **Historical Analysis:** Browse folders `01` and `02` for baseline data structures.
2.  **Weekend Modeling:** Check folder `03` for practice session logic.
3.  **2026 Testing Pipeline:** Navigate to folder `04`. This is the most advanced section of the repo. 
    * Process daily CSVs using `F1_Pace_Analysis_Preseason_2026.m`.
    * Generate the final global report using `post_analysis_v4.m`.

---

## 📬 Contact & Portfolio
**Author:** Thanasis Charalambous  
**Role:** Data Analysis Engineer  
*Specializing in the intersection of Data Engineering and Motorsport Strategy.*

---
*Copyright (c) 2025-2026 Thanasis Charalambous. Licensed under the MIT License.*
