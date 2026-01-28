# 🔄 Remote Windows Update Execution (PowerShell)

## 📌 Overview

Without an enterprise update management solution (such as **WSUS** or **Microsoft Intune**), remotely invoking Windows Updates on Windows 10/11 systems is **not a straightforward task**. Microsoft security controls (UAC, SYSTEM context requirements, and update orchestration) limit the ability to reliably trigger updates remotely.

This project implements a **reliable, enterprise‑proven workaround** using **PowerShell** and **Scheduled Tasks** to install Windows Updates under the **SYSTEM** account.

---

## 🧭 Approach Summary

The solution follows these steps:

1. 🧩 **Install PSWindowsUpdate Module**  
   A PowerShell script downloads and installs the `PSWindowsUpdate` module, which provides programmatic access to Windows Update functionality.

2. 📦 **Deploy Update Script**  
   A ZIP file is downloaded, its contents are extracted, and the `InstallUpdates.ps1` script is copied to the `C:\Temp` directory on the target system.

3. 🗓️ **Create Scheduled Task**  
   A Scheduled Task is created to run `InstallUpdates.ps1` under the **SYSTEM** account with the highest privileges. This ensures updates can be installed even when no user is logged in and bypasses UAC limitations.

4. 🚀 **Remote Execution**  
   The scheduled task is remotely triggered using PowerShell, allowing updates to be initiated on demand.

5. 🧹 **Optional Cleanup**  
   After execution, the scheduled task and associated files may be removed as part of a cleanup process.

---

## ✅ Why This Works

- 🔐 Runs updates in the **SYSTEM context** (required for reliability)
- 🛠️ Works without WSUS or Intune
- 💻 Compatible with Windows 10 and Windows 11
- 🤖 Safe for automation, scheduled execution, and enterprise environments

---

## 📋 Requirements

- 🧑‍💼 Administrator privileges
- 🖥️ PowerShell 5.1 or later
- 🌐 Network access to download required files
- ⏱️ Task Scheduler service enabled

---

## ⚠️ Notes

- ⏳ Feature updates may still follow Microsoft deferral policies
- 🔄 Reboots may be required depending on installed updates
- 🧼 Cleanup steps are optional and environment‑dependent

---

## 📄 Disclaimer

This solution is intended for environments **without centralized update management**. In managed enterprise environments, **WSUS or Microsoft Intune** remains the recommended and supported approach.

