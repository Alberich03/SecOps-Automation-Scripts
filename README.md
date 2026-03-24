# Security Operations (SecOps) Automation Scripts

## 📌 Overview
This repository contains a collection of automation scripts developed to streamline and accelerate Dynamic Application Security Testing (DAST) and vulnerability assessments. These scripts were utilized to conduct non-disruptive, large-scale security scanning across multiple web applications, converting complex tool outputs into structured reports.

## 🛠️ Scripts Included

* **`Zap_Scan.sh`**: A Bash script that automates OWASP ZAP via its API to perform authenticated/unauthenticated scans, parse the results, and automatically generate comprehensive HTML/PDF vulnerability reports.
* **`wapiti_scan_t.sh`**: Automates web application vulnerability scanning using Wapiti, configured to efficiently map endpoints and detect injection flaws (XSS, SQLi).
* **`nuclei_scan.ps1` & `run_nuclei_scan.bat`**: PowerShell and Batch scripts designed to automate Nuclei for fast, template-based vulnerability scanning. These scripts handle bulk target processing and output log management.

## 🎯 Purpose & Impact
These tools were created to:
- Reduce manual scanning time for large infrastructure assessments.
- Ensure consistent and reproducible security testing methodologies.
- Facilitate the extraction of actionable security logs for threat analysis.

## ⚠️ Disclaimer
All scripts in this repository are intended for educational purposes and authorized security assessments only.
