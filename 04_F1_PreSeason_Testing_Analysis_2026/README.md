# 🏎️ 04 | F1 2026 Pre-Season Testing Analysis (Bahrain)

## 📌 Project Overview
This project provides a data-driven audit of the 2026 Formula 1 grid based on 6 days of testing. I developed a dual-stage MATLAB pipeline that automates everything from driver identification to multi-day trend analysis.

## 🛠️ The Technical Pipeline

### Phase 1: Daily Analysis Engine (`F1_Pace_Analysis_Preseason_2026.m`)
The core engine handles "messy" raw data through:
* **Dynamic Metadata Extraction:** Scans the CSV file headers to automatically detect the driver lineup for each session, preventing manual mapping errors.
* **Stint Identification:** Uses cumulative sum masks to separate high-fuel long runs from low-fuel qualifying simulations.
* **Degradation Modeling:** Fits a linear regression to lap times to find the tire wear coefficient ($s/lap$).
* **Automated Export:** Generates session-specific folders with multi-sheet Excel reports and pace figures.

### Phase 2: Unified Master Aggregator (`post_analysis_v4.m`)
Synthesizes 6 days of testing into an executive summary:
* **Theoretical Peak Analysis:** Identifies "Compound Winners" by aggregating the best sectors across the entire week.
* **Workload Auditing:** Visualizes team reliability by tracking mileage progression.



## 📊 2026 Testing Pecking Order
| Category | Leader | Benchmark | Strategic Verdict |
| :--- | :--- | :--- | :--- |
| **Peak Performance** | **Charles Leclerc** | **1:31.992** | Ferrari leads the qualifying simulation charts. |
| **Operational Reliability** | **George Russell** | **349 Laps** | Mercedes shows the most robust power unit package. |
| **Race Pace Efficiency** | **Max Verstappen** | **0.073s/lap** | Red Bull maintains superior tire preservation. |

## 🚀 How to Run

1.  User needs to update the top section,  0 📂 DIRECTORY SETUP, of `F1_Pace_Analysis_Preseason_2026.m` for the specific day (1-6):
    change X to 1-6 based on Testing day that the user want to analyse.
2.  Ensure all daily session data is stored in folders following the `F1_Testing_Day_X` convention.
3.  Run `F1_Pace_Analysis_Preseason_2026.m` to generate daily reports.
4.  Execute `post_analysis_v4.m` to generate the global summary and final visualizations in the `F1_Final_Post_Analysis` directory.

---
**Author:** Thanasis Charalambous  
**Role:** Data Analysis Engineer  
**Data Source:** [TracingInsights](https://tracinginsights.com/)
