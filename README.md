# 🏁 F1 Performance & Data Analytics Ecosystem
**Developer:** Thanasis Charalambous | **Role:** Data Analysis Engineer

A comprehensive suite of MATLAB-based engineering tools designed to extract competitive intelligence from Formula 1 telemetry and historical datasets. This repository tracks the evolution from historical database management to advanced, automated pre-season testing pipelines.

---

## 📂 Project Portfolio

### 01. Formula 1 Race Data Analysis (Historical)
**Focus:** Database Merging & Strategy Visualization  
This project analyzes and visualizes historical lap times and pit stop strategies using comprehensive CSV datasets.

* **Features:** Automated data loading; Year/Race filtering; Merging of driver, constructor, and lap data.
* **Visuals:** Lap time evolution plots with automated pit-stop markers for top finishers.
* **Data Source:** [F1 World Championship Dataset (1950-Present)](https://www.kaggle.com/datasets/rohanrao/formula-1-world-championship-1950-2020/data) via Vopani/Kaggle.

### 02. 🏎️ Race Pace Audit: 2025 São Paulo GP (NOR)
**Focus:** Statistical Filtering & Fuel Normalization  
A large-scale statistical analysis of Lando Norris's performance, applying 2-sigma filtering to isolate true racing pace.

* **Fuel Correction Model:** $T_{Corrected} = T_{Raw} - (L_{Remaining} \times 0.041575)$.
* **2-Sigma ($\sigma$) Filtering:** Statistical outlier rejection ($\mu + 2\sigma$) to remove traffic and driver errors.
* **Degradation Calculation:** Linear regression on fuel-corrected times to find the tire wear coefficient in ms/lap.
* **Results:** Identified a negative degradation (-9.9 ms/lap) on the final Medium stint, indicating pace improvement as fuel decreased.



### 03. 📊 Practice Pace Analysis: 2025 Abu Dhabi GP
**Focus:** Multi-Driver Benchmarking & Title Decider Simulation  
Comparative analysis of the three title contenders (NOR, VER, PIA) across Practice 1, 2, and 3 to predict the final qualifying and race hierarchy.

| Pace Scenario | Compound | NOR | VER (Gap) | PIA (Gap) |
| :--- | :--- | :--- | :--- | :--- |
| **QUALI SIMS** | SOFT | 1:23.083 | +0.363 | +0.510 |
| **RACE SIMS** | MEDIUM | 1:29.270 | +0.407 | +0.471 |

* **Outputs:** Generated stint-based scatter plots and Excel pace comparisons organized by tire life and compound.

### 04. 🏎️ 2026 Pre-Season Testing Analysis (Bahrain)
**Focus:** Automated Data Engineering Pipeline  
A dual-stage pipeline that automates the processing of 144 hours of raw 2026 testing telemetry into executive-level insights.

* **Dynamic Metadata Extraction:** Scans CSV headers to automatically detect driver lineups, preventing manual mapping errors.
* **Unified Aggregator:** Synthesizes 6 days of testing into a "Global Source of Truth" report.
* **2026 Testing Pecking Order:**
    * **Peak Performance:** Charles Leclerc (1:31.992)
    * **Reliability:** George Russell (349 Laps)
    * **Race Pace Efficiency:** Max Verstappen (0.073s/lap)



---

## 🛠️ Technical Skillset & Methodology

| Technique | Application | Formula / Model |
| :--- | :--- | :--- |
| **Fuel Normalization** | Performance isolation | $T_{Raw} - (Fuel \times Factor)$ |
| **Degradation Rate** | Tire wear analysis | Linear Regression Slope |
| **Outlier Rejection** | Traffic/Error removal | 2-Sigma ($\sigma$) Statistical Filter |
| **Pace Smoothing** | Trend visualization | 4th-Degree Polynomial Regression |

---

## 🚀 How to Run
1.  **Race Analysis (01):** Set `dataFolder` to your CSV path and choose a Race ID in MATLAB.
2.  **Post-Race Audit (02):** Execute `F1_Post_Race_Analysis.m` to generate fuel-corrected stint reports.
3.  **Practice Analysis (03):** Run `F1_Pace_Analysis_Multiple_Drivers_FINAL.m` for Abu Dhabi benchmarking.
4.  **Testing Pipeline (04):** * Update `DIRECTORY SETUP` (Day X) in `F1_Pace_Analysis_Preseason_2026.m`.
    * Execute daily scripts, then run `post_analysis_v4.m` for global aggregation.

---
**Author:** Thanasis Charalambous | **Role:** Data Analysis Engineer  
**Data Sources:** Tracing Insights & Kaggle (Vopani).  
*Disclaimer: This repository is for educational and non-commercial purposes only.*
