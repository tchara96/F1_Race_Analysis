## 🏎️ F1 Race Pace Analysis: Lando Norris (NOR) - 2025 São Paulo Grand Prix

## Project Overview

This repository documents the results of a comprehensive, large-scale **statistical analysis** of Lando Norris's performance during the **2025 São Paulo Grand Prix**.

The project uses a **MATLAB script** to process raw telemetry data, applying stringent **statistical filtering (2-sigma)** and **fuel normalization** to accurately isolate true racing pace and determine **precise tire degradation rates (ms/lap)** for each stint.

---

## 🛠️ Technical Methodology

The MATLAB script utilizes several key techniques for robust data analysis:

1.  **Data Filtering:** In-laps, Out-laps, Safety Car periods, and mandatory 'Status $\ne$ 1' laps are removed to ensure only laps run under clear track conditions are considered.
2.  **2-Sigma ($\sigma$) Filtering:** A second layer of statistical filtering is applied. Any remaining lap time exceeding the mean lap time plus two standard deviations ($\mu + 2\sigma$) for the 'clear laps' dataset is discarded. This removes minor traffic/driver errors unflagged by the official status column.
3.  **Fuel Correction (Normalization):** Lap times are normalized to an empty-tank baseline using a pre-determined fuel correction factor ($0.041575$ seconds per lap). This eliminates the performance gain from fuel burn, allowing for a precise assessment of **tire and car performance independent of fuel load**.
    $$T_{\text{Corrected}} = T_{\text{Raw}} - (L_{\text{Remaining}} \times 0.041575)$$
4.  **Degradation Calculation:** **Linear regression** is performed on the *Fuel-Corrected* lap times ($y$) versus the **Tire Life** ($x$) for each stint. The slope of the line gives the precise degradation rate in seconds per lap, which is then presented as **milliseconds per lap (ms/lap)**.

### ⚙️ Core Mathematical Models

| Model | Purpose | Formula / Function |
| :--- | :--- | :--- |
| **Fuel Normalization** | Isolates performance from fuel load. | $$T_{\text{Corrected}} = T_{\text{Raw}} - (L_{\text{Remaining}} \times 0.041575)$$ |
| **Degradation Rate** | Calculates tire wear (ms/lap). | **Linear Regression** |
| **Pace Smoothing (F2)** | Visualizes the pace trend over a stint. | **4th-Degree Polynomial Regression** |

---

## 📊 Results Summary

### 🏁 Overall Race Statistics

| Metric | Value | Lap Number (L) |
| :--- | :--- | :--- |
| **Race Strategy** | MEDIUM $\to$ SOFT $\to$ MEDIUM | N/A |
| **Position Change** | 1st $\to$ 1st (**+0**) | N/A |
| **Total Race Time** | 1:32:01:596 | N/A |
| **Statistically Robust Laps** | 57 / 71 | N/A |
| **🥇 Best Lap (Raw)** | 1:13:040 | L66 |
| **⛽ Best Lap (Fuel-Corrected)** | **1:10:870** | L9 |
| **Overall Consistency** (CV) | **86.74%** | N/A |

### 🛞 Stint Pace and Degradation

The final Medium stint exhibited **negative degradation** ($-\mathbf{9.9}$ ms/lap), meaning the pace improved as the tire life increased, successfully leveraging the reduced fuel load.

| Stint | Compound | Stint Laps | Best Lap | Avg Lap Time | **Degradation (ms/lap)** |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | MEDIUM | 30 | 1:13:489 (L9) | 1:21:719 | **43.0** |
| **2** | SOFT | 20 | 1:13:968 (L36) | 1:15:433 | **22.0** |
| **3** | MEDIUM | 21 | 1:13:040 (L66) | 1:14:351 | **-9.9** (Pace Improved) |

---

## 🖼️ Visualizations & Deliverables

The analysis generates six key figures and a complete text output report.

| File | Type | Description | Link |
| :--- | :--- | :--- | :--- |
| **F1\_Post\_Race\_Analysis.m** | MATLAB Script | The primary script containing all data processing, calculations, and plotting code. | [https://github.com/tchara96/F1_Race_Analysis/blob/main/02_F1_Post_Race_Analysis/F1_Post_Race_Analysis.m] |
| **Results from Race data Analysis.txt** | Text Report | Full statistical output, including detailed stint tables and coefficient calculations. | [https://github.com/tchara96/F1_Race_Analysis/blob/main/02_F1_Post_Race_Analysis/Results%20from%20Race%20data%20Analysis.txt]|
| **Raw Data (.csv)** | Data Source | The original telemetry data file used for the analysis. | [https://github.com/tchara96/F1_Race_Analysis/blob/main/02_F1_Post_Race_Analysis/s%C3%A3o-paulo-grand-prix-race-NOR-TracingInsights.com-datatable-2025-11-19.csv] |
| **F6: Normalized Pace** | **CRITICAL PLOT** | Plots **Fuel-Corrected Lap Times** against **Tire Life** to show *true* performance degradation. | **[https://github.com/tchara96/F1_Race_Analysis/blob/main/02_F1_Post_Race_Analysis/Figure%206.png]** |
| **F3: Stint Pace Distribution** | Consistency Check | Jittered scatter plot showing mean/median to assess lap time spread and **consistency**. | **[https://github.com/tchara96/F1_Race_Analysis/blob/main/02_F1_Post_Race_Analysis/Figure%203.png]** |
| **All Other Figures** | Support Plots | F1 (Raw Pace), F2 (Smoothed Pace), F4 (Raw Degradation), F5 (Position Progression). | F1:**[https://github.com/tchara96/F1_Race_Analysis/blob/main/02_F1_Post_Race_Analysis/Figure%201.png]** 
F2:**[https://github.com/tchara96/F1_Race_Analysis/blob/main/02_F1_Post_Race_Analysis/Figure%202.png]** 
F4:**[https://github.com/tchara96/F1_Race_Analysis/blob/main/02_F1_Post_Race_Analysis/Figure%204.png]** 
F5:**[https://github.com/tchara96/F1_Race_Analysis/blob/main/02_F1_Post_Race_Analysis/Figure%205.png]**|

---

## 💻 Repository Structure

* **Data Source:** [Tracing Insights](https://tracinginsights.com/)
* `F1_Post_Race_Analysis.m`: The primary MATLAB script for processing, calculation, and visualization.
* `são-paulo-grand-prix-race-NOR-TracingInsights.com-datatable-2025-11-19.csv`: Raw data file.
* `Results from Race data Analysis.txt`: Full text output of the statistical calculations and summary tables.
* `README.md`: This summary file.
* `Figure 1.png` - `Figure 6.png`: All generated visualization plots (linked above).

## 🔬 Key Skills Demonstrated

* **Advanced Data Processing (MATLAB):** Expertise in using MATLAB for robust cleaning, filtering, and large-scale data manipulation.
* **Automotive Data Science:** Practical application of domain-specific techniques like **fuel normalization** and **tire degradation modeling**.
* **Statistical Filtering:** Implementation of **2-Sigma control limits** ($\mu \pm 2\sigma$) for high-accuracy outlier rejection in noisy data sets.
* **Predictive Modeling:** Utilization of linear and polynomial regression for determining degradation rates and pace trends.
