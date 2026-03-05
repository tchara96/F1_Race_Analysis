# 🏎️ 04 | F1 2026 Pre-Season Testing Analysis (Bahrain)

## 📌 Project Overview
This project provides a comprehensive data-driven audit of the 2026 Formula 1 grid based on 6 days of intensive testing at the Bahrain International Circuit. Using raw timing and telemetry data extracted from **TracingInsights**, I developed a dual-stage MATLAB pipeline to identify the true performance hierarchy and reliability trends ahead of the season opener.



## 🛠️ The Technical Pipeline
The project is architected as an end-to-end data pipeline, moving from raw CSV ingestion to multi-day strategic aggregation.

### Phase 1: Daily Analysis Engine (`F1_Pace_Analysis_Preseason_2026.m`)
The core engine processes raw lap data to extract stint-specific metrics:
* **Stint Identification:** Uses cumulative sum masks to separate high-fuel long runs from low-fuel qualifying simulations.
* **Degradation Modeling:** Calculates the linear regression of lap times to determine the tire wear coefficient ($s/lap$).
* **Automated Reporting:** Generates session-specific folders containing multi-sheet Excel reports and pace degradation figures.

### Phase 2: Unified Master Aggregator (`post_analysis_v4.m`)
The "Data Architect" layer that synthesizes 144 hours of testing into a single source of truth:
* **Longitudinal Synthesis:** Crawls daily directories to merge data into a unified dataset.
* **Theoretical Peak Analysis:** Identifies "Compound Winners" by aggregating the best sectors across the entire test.
* **Workload Auditing:** Visualizes team reliability by tracking cumulative mileage progression.

## 📊 Key Insights (Aggregated Results)

### **The 2026 Testing Pecking Order**
| Category | Leader | Benchmark | Strategic Verdict |
| :--- | :--- | :--- | :--- |
| **Peak Performance** | **Charles Leclerc (Ferrari)** | **1:31.992** | The headline pace; Ferrari leads the qualifying simulation charts. |
| **Operational Reliability** | **George Russell (Mercedes)** | **349 Laps** | Highest mileage; Mercedes shows the most robust thermal management. |
| **Race Pace Efficiency** | **Max Verstappen (Red Bull)** | **0.073s/lap** | Superior tire preservation during long-run simulations on Softs. |
| **Efficiency Breakthrough** | **Kimi Antonelli (Mercedes)** | **1:33.669** | Exceptional rookie adaptation, matching veteran sector times on Softs. |

### **Fastest Laps by Compound**
* **HARD:** Oscar Piastri (1:33.624)
* **MEDIUM:** Charles Leclerc (1:31.992)
* **SOFT:** Kimi Antonelli (1:33.669)



## 📁 Repository Structure
* **`/Data`**: Raw `.csv` files sourced from TracingInsights and processed `.xlsx` masters.
* **`/Scripts`**: MATLAB source code for daily processing and the final master aggregator.
* **`/Results`**: Automated exports including the `ULTIMATE_AGGREGATED_REPORT` and visual performance trends.

## 🚀 How to Run
1.  The user needs to modify in code section, %% 0 📂 DIRECTORY SETUP. Modify the four X to 1-6 regarding which testing wants the user to analyse.
2.  Ensure all daily session data is stored in folders following the `F1_Testing_Day_X` convention.
3.  Run `F1_Pace_Analysis_Preseason_2026.m` to generate daily reports.
4.  When finish all 6 Testing days, execute `post_analysis_v4.m` to generate the global summary and final visualizations in the `F1_Final_Post_Analysis` directory.

---
**Author:** Thanasis Charalambous  
**Role:** Data Analysis Engineer  
**Data Source:** [TracingInsights](https://tracinginsights.com/)
