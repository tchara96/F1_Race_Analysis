## 🏎️ F1 Race Pace Analysis: Lando Norris (NOR) - 2025 São Paulo Grand Prix

This repository contains the MATLAB script and core statistical findings from a robust race pace analysis of Lando Norris's performance during the **2025 São Paulo Grand Prix**.

The analysis applies **statistical filtering (2-sigma)** and **fuel normalization** to raw telemetry data to isolate 'true pace laps' and accurately determine tire degradation rates (ms/lap) for each stint.

---

## 🛠️ Technical Methodology

The MATLAB script utilizes several key techniques for robust data analysis:

1.  **Data Filtering:** In-laps, Out-laps, Safety Car periods, and mandatory 'Status $\ne$ 1' laps are removed to ensure only laps run under clear track conditions are considered.
2.  **2-Sigma ($\sigma$) Filtering:** A second layer of statistical filtering is applied. Any remaining lap time exceeding the mean lap time plus two standard deviations ($\mu + 2\sigma$) for the 'clear laps' dataset is discarded. This removes minor traffic/driver errors unflagged by the official status column.
3.  **Fuel Correction (Normalization):** Lap times are normalized to an empty-tank baseline using a pre-determined fuel correction factor ($0.041575$ seconds per lap). This eliminates the performance gain from fuel burn, allowing for a precise assessment of **tire and car performance independent of fuel load**.
    $$T_{\text{Corrected}} = T_{\text{Raw}} - (L_{\text{Remaining}} \times 0.041575)$$
4.  **Degradation Calculation:** Linear regression ($\text{polyfit}(x, y, 1)$) is performed on the *Fuel-Corrected* lap times ($y$) versus the **Tire Life** ($x$) for each stint. The slope of the line gives the precise degradation rate in seconds per lap, which is then presented as **milliseconds per lap (ms/lap)**. 

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

The final Medium stint exhibited **negative degradation**, meaning the pace improved as the tire life increased, successfully leveraging the reduced fuel load.

| Stint | Compound | Stint Laps | Best Lap | Avg Lap Time | **Degradation (ms/lap)** |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | MEDIUM | 30 | 1:13:489 (L9) | 1:21:719 | **43.0** |
| **2** | SOFT | 20 | 1:13:968 (L36) | 1:15:433 | **22.0** |
| **3** | MEDIUM | 21 | 1:13:040 (L66) | 1:14:351 | **-9.9** (Pace Improved) |

---

## 🖼️ Visualizations

The analysis generates six key figures to visualize different aspects of pace and consistency.

| Figure | Description | Key Insight |
| :---: | :--- | :--- |
| **F1** | Race Pace by Stint and Compound | Raw lap time trends over the whole race. |
| **F3** | Stint Pace Distribution | Shows lap time spread and mean/median for consistency. |
| **F6** | **Normalized Pace vs. Tire Life** | **CRITICAL PLOT:** True degradation of each tire compound (fuel effect removed).  |

---

## 💻 Repository Structure

* `são-paulo-grand-prix-race-NOR-TracingInsights.com-datatable-2025-11-19.csv`: Raw data file.
* `f1_pace_analysis_norris_2025.m`: The primary MATLAB script for processing, calculation, and visualization.
* `README.md`: This summary file.
* `/figures`: Directory containing the six output plots (F1 - F6).
