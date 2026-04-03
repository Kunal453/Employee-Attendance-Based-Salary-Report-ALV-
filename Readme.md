# 📊 SAP ABAP Salary & Attendance Processing (ALV Report)

## 📌 Overview
This project is an SAP ABAP report that processes **Employee Attendance and Salary Data** and displays results using **ALV Grid**.

The program allows users to:
- View **attendance details**
- Calculate **salary based on attendance**
- Display **earnings, deductions, PF, subtotal, and total salary**
- Drill down into **employee master details** via double-click

---

## 🚀 Features

### ✅ Attendance Processing
- Calculates total days based on month (including leap year logic)
- Computes attendance percentage
- Displays remarks:
  - *Low Attendance*
  - *Excellent Attendance*

### 💰 Salary Processing
- Fetches salary components (earnings & deductions)
- Adjusts base salary based on attendance
- Calculates:
  - PF (12% of Basic)
  - Subtotal
  - Final Total Salary
- Displays salary breakdown in ALV

### 🔍 Interactive ALV Report
- ALV Grid Display using `REUSE_ALV_GRID_DISPLAY`
- Top-of-page headers with:
  - Report title
  - Total salary
  - Date
- Double-click functionality:
  - View detailed employee information

---

## 🧾 Selection Screen

### Inputs:
- **Employee Number (Range)**
- **Month (YYYYMM)**

### Options:
- 🔘 Attendance Report  
- 🔘 Salary Report  

---

## 🏗️ Program Structure

### Main Flow:
1. Fetch Attendance Data  
2. Process Attendance  
3. (Optional) Fetch Salary Data  
4. Process Salary  
5. Display ALV Report  

---

## 📂 Key Internal Tables

| Table Name        | Description |
|------------------|------------|
| `gt_mtdatt`      | Attendance data |
| `gt_saltrn`      | Salary transactions |
| `gt_mtdatt_res`  | Processed attendance |
| `gt_saltrn_res`  | Processed salary |
| `gt_empsal`      | Employee master + salary |
| `gt_output`      | Final employee display |

---

## ⚙️ Important Calculations

### 📊 Attendance %
```
Attendance % = (Days Present / Total Days) * 100
```

### 💰 Salary Adjustment
```
Adjusted Salary = Basic Salary * (Days Present / Total Days)
```

### 🏦 PF Calculation
```
PF = Basic Salary * 12%
```

---

## 🖥️ ALV Reports

### 📌 Attendance ALV
- Employee Number
- Month
- Days Present
- Total Days
- Remarks

### 📌 Salary ALV
- Employee Number
- Salary Head
- Salary Amount
- Currency
- Salary Type (Earning/Deduction)

---

## 🔄 Drill-Down Feature
- Double-click on **Employee Number**
- Displays:
  - Personal Details
  - Bank Info
  - Salary Info

---

## 🛠️ Technologies Used
- SAP ABAP
- ALV Grid (`REUSE_ALV_GRID_DISPLAY`)
- Internal Tables & Work Areas
- Modularization (FORM routines)

---

## 📅 Output Highlights
- Dynamic ALV Reports
- Top-of-page summary with:
  - Employee Total Salary
  - Date of generation
- Clean and structured output

---

## ⚠️ Notes
- Month input is mandatory
- Employee range can be optional (based on requirement)
- Program supports both **single and multiple employees**

---

## 👨‍💻 Author
**Kunal Patil**  
SAP ABAP Developer (Fresher)
