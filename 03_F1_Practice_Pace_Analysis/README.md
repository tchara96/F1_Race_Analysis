
# 🏎️📊 F1 Practice Pace Analysis (2025 Abu Dhabi Grand Prix)

This project contains the MATLAB script and associated data files for analyzing long-run and short-run pace from the three practice sessions of the title decider, 2025 Abu Dhabi Grand Prix. The goal of this analysis is to determine the relative performance over quali simulations and race simulations of the 3 title contenders-drivers leading up to Qualifying and the Race.

## 📁 Project Structure

The project is organized into the following directories and key files:

| File/Folder | Description |
| :--- | :--- |
| **`F1_Pace_Analysis_Multiple_Drivers_FINAL.m`** | The **main MATLAB script** used to load the CSV data, clean the lap times, filter for valid long/short stints, calculate pace metrics, and generate all result plots (`.fig` files). |
| `abu-dhabi-grand-prix-practice-X.csv` | **Raw data files** containing lap times, tire compound, and other telemetry data for Practice 1, 2, and 3. |
| `pace comparison.xlsx` | An **Excel summary** of the calculated final pace metrics (e.g., mean pace for specific stint types) across all sessions and drivers. |
| **`Results/`** | Contains the generated output from the analysis script, organized by practice session. |
| **`Results/Practice X/`** | Contains the output figures and text summaries for each specific session (P1, P2, P3). |

## 💾 Data Source

The raw data files (`abu-dhabi-grand-prix-practice-X.csv`) used for this analysis were obtained from the following public source:

* **Website:** [Tracing Insights](https://tracinginsights.com/)

## 🛠️ Requirements

To run the analysis script and view the figures, you will need:

* **MATLAB** (R2018a or newer recommended).

## ▶️ How to Run the Analysis

1.  Place all files and folders in your MATLAB working directory.
2.  Open **`F1_Pace_Analysis_Multiple_Drivers_FINAL.m`** in the MATLAB editor.
3.  Ensure the raw data files (`.csv`) are correctly referenced in the script.
4.  Run the script by pressing the **Run** button or typing `F1_Pace_Analysis_Multiple_Drivers_FINAL` in the Command Window.

The script will generate the results at the command window and the `.fig` plots. 

## 🏁 Final Pace Scenario Comparison (P1, P2, P3)

This table summarizes the fastest lap times (Qualifying Simulations) and the best average pace (Race Simulations) achieved by the featured drivers across all three practice sessions. Gaps are measured relative to the fastest time in that specific scenario.

| Pace Scenario | Compound | NOR | VER | PIA |
| :--- | :--- | :--- | :--- | :--- |
| **QUALI SIMS** (Fastest Lap) | **SOFT** | **1:23.083** | 1:23.446 (+0.363) | 1:23.593 (+0.510) |
| (Low Fuel) | **MEDIUM** | **1:24.292** | 1:24.399 (+0.107) | 1:24.434 (+0.142) |
| | **HARD** | - | **1:25.468** | - |
| **RACE SIMS** (Average Lap Time) | **SOFT** | **1:26.071** | - | 1:26.492 (+0.421) |
| (High Fuel) | **MEDIUM** | **1:29.270** | 1:29.677 (+0.407) | 1:29.741 (+0.471) |
| | **HARD** | - | **1:29.693** | - |

## 📊 Analysis Outputs

The `Results` folder contains the detailed output for each session:

### **Text Summaries**
* `Results/Practice X/PRACTICE X results.txt` (or similar): Textual summary of key pace metrics (e.g., average lap time, fastest lap time, etc) for each driver on each tire compound (`SOFT`, `MEDIUM`, `HARD`).

### **Visualization Figures**

The following `.fig` plots are generated and stored per practice session:

| Figure Name | Description | Axis Data (Y-axis: Lap Time) |
| :--- | :--- | :--- |
| **Figure 1** | All Drivers Pace: All **VALID** Stints (Clear Laps) | X-axis: Lap Tyre Age |
| **Figure 2** | Drivers Pace: **SOFT** Tyre Stints (Valid Laps Only) | X-axis: Tyre Life |
| **Figure 3** | Drivers Pace: **MEDIUM** Tyre Stints (Valid Laps Only) | X-axis: Tyre Life |
| **Figure 4** | Drivers Pace: **HARD** Tyre Stints (Valid Laps Only) | X-axis: Tyre Life |
| **Figure 5** | ALL Laps Pace, all laps of the session (**1st Driver**) | X-axis: Tyre Age |
| **Figure 6** | ALL Laps Pace, all laps of the session (**2nd Driver**) | X-axis: Tyre Age |
| **Figure 7** | ALL Laps Pace, all laps of the session (**3rd Driver**) | X-axis: Tyre Age |

## 📝 License

This project is for personal use and study purposes only.
