#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import shutil
import subprocess
import time
from datetime import datetime

try:
    import yara
except ImportError:
    print("[!] YARA library is not installed. To install: pip install yara-python")
    sys.exit(1)

try:
    import psutil
except ImportError:
    print("[!] psutil library is not installed. To install: pip install psutil")
    sys.exit(1)

# ============================================================
# 1. YARA RULE (embedded directly)
# ============================================================
YARA_RULE = """
rule Evil_Orange_Discord_C2_Agent
{
    meta:
        description = "Evil_Orange Discord C2 Agent (Nim)"
        author = "hackpatato"
        reference = "https://github.com/hackpatato/EV-L-ORANGE-MSG"
        date = "2026-08-18"
        severity = "high"
        confidence = "high"
        
    strings:
        $nim1 = "nim"
        $nim2 = "NimMain"
        $nim3 = "NimStringV2"
        $evil_title   = "Evil_Orange" wide ascii
        $welcome      = "Welcome to Evil_Orange" wide ascii
        $vodka        = "VODKA" wide ascii
        $xor_enc      = "xorEncrypt" wide ascii
        $xor_dec      = "xorDecrypt" wide ascii
        $install_pers = "installPersistence" wide ascii
        $peel2        = "peel2" wide ascii
        $copy_startup = "copyToStartup" wide ascii
        $poll_cmd     = "poll_commands" wide ascii
        $send_discord = "send_discord_message" wide ascii
        $get_env      = "getEnv(\\"DISCORD_TOKEN\\"" wide ascii
        $get_env2     = "getEnv(\\"DISCORD_CHANNEL\\"" wide ascii
        $get_env3     = "getEnv(\\"VODKA\\"" wide ascii
        $discord_api  = "discord.com/api/v10/channels/" wide ascii
        $discord_auth = "Authorization: Bot " wide ascii
        $messages     = "/messages" wide ascii
        $limit1       = "messages?limit=1" wide ascii
        $persist_nm   = "NativeMessagingHosts" wide ascii
        $persist_ext  = "ExtensionInstallForcelist" wide ascii
        $persist_exe  = "WindowsOrangePeller.exe" wide ascii
        $persist_dll  = "WindowsSystem64.dll.exe" wide ascii
        $persist_svc  = "servis.exe" wide ascii
        $startup_path = "Start Menu\\\\Programs\\\\Startup" wide ascii
        $reg_edge1    = "HKCU\\\\Software\\\\Microsoft\\\\Edge" wide ascii
        $reg_edge2    = "HKCU\\\\Software\\\\Policies\\\\Microsoft\\\\Edge" wide ascii
        $reg_add      = "reg.exe add" wide ascii
        $exec_cmd     = "!exec " wide ascii
        $exec_cmd_ex  = "execCmdEx" wide ascii
        $err_xor      = "xor key error" wide ascii
        $err_xor2     = "XOR İS 64 HEX" wide ascii
        $err_18       = "ERROR NUMBER : 18" wide ascii
        $err_42       = "error 42 . HOW YOU CAN MAKE İT ?" wide ascii
        $err_decrypt  = "a error at xor decrypt !" wide ascii
        $xor_pattern  = { 78 6f 72 20 6b 65 79 20 65 72 72 6f 72 }
        $base64_enc   = "encode(result)" wide ascii
        $base64_dec   = "decode(b64data)" wide ascii
        $turkish1     = "LANET OLASI" wide ascii
        $turkish2     = "ŞİMDİ" wide ascii
        $turkish3     = "yehuuuu" wide ascii
        
    condition:
        ( $nim1 or $nim2 or $nim3 ) and
        (
            ( $evil_title and $vodka ) or
            ( $xor_enc and $xor_dec ) or
            ( $install_pers and $peel2 ) or
            ( $discord_api and $discord_auth and $messages ) or
            ( $persist_nm or $persist_ext or $persist_exe or $persist_dll or $persist_svc ) or
            ( $reg_edge1 and $reg_add ) or
            ( $reg_edge2 and $reg_add ) or
            ( $exec_cmd and $exec_cmd_ex ) or
            ( $err_xor and $err_xor2 ) or
            ( $turkish1 and $turkish2 )
        ) or
        ( $xor_pattern and $base64_enc and $vodka )
}
"""

# ============================================================
# 2. QUARANTINE FUNCTION
# ============================================================
def quarantine_file(file_path):
    """Moves the file to a quarantine folder (safe, does not delete permanently)."""
    try:
        # Quarantine folder: C:\Quarantine_EvilOrange
        quarantine_base = os.path.join(os.environ.get('SystemDrive', 'C:'), 'Quarantine_EvilOrange')
        os.makedirs(quarantine_base, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_name = os.path.basename(file_path)
        dest_path = os.path.join(quarantine_base, f"{timestamp}_{file_name}")
        
        shutil.move(file_path, dest_path)
        print(f"[+] Quarantined: {file_path} -> {dest_path}")
        return True
    except Exception as e:
        print(f"[!] Quarantine error ({file_path}): {e}")
        return False

# ============================================================
# 3. SCANNING FUNCTIONS
# ============================================================
def compile_yara_rule():
    """Compiles the embedded YARA rule."""
    try:
        return yara.compile(source=YARA_RULE)
    except yara.SyntaxError as e:
        print(f"[!] YARA rule syntax error: {e}")
        sys.exit(1)

def scan_file_with_yara(rules, file_path):
    """Scans a single file with YARA. Returns True if matched."""
    if not os.path.isfile(file_path):
        return False
    try:
        matches = rules.match(file_path)
        return len(matches) > 0
    except Exception:
        # Permission errors, etc. - skip
        return False

def scan_specific_paths(rules):
    """Scans the hardcoded persistence paths found in the original code."""
    detected_files = []
    
    # 1. C:\Windows\WinSxS\WindowsOrangePeller.exe
    path1 = os.path.join(os.environ.get('SystemRoot', 'C:\\Windows'), 'WinSxS', 'WindowsOrangePeller.exe')
    # 2. %APPDATA%\WindowsSystem64.dll.exe
    path2 = os.path.join(os.environ.get('APPDATA', ''), 'WindowsSystem64.dll.exe')
    # 3. %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\servis.exe
    startup_base = os.path.join(os.environ.get('APPDATA', ''), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
    path3 = os.path.join(startup_base, 'servis.exe')
    
    all_paths = [path1, path2, path3]
    
    print("[*] Scanning known persistence paths...")
    for p in all_paths:
        if os.path.exists(p):
            if scan_file_with_yara(rules, p):
                detected_files.append(p)
                print(f"[!] DETECTED: {p}")
            else:
                print(f"[+] Clean (or inaccessible): {p}")
        else:
            print(f"[-] File does not exist: {p}")
    
    return detected_files

def scan_running_processes(rules):
    """Scans the executable files of all running processes."""
    detected_procs = []
    print("[*] Scanning running processes (this may take a while)...")
    
    for proc in psutil.process_iter(['pid', 'name', 'exe']):
        try:
            exe_path = proc.info['exe']
            if exe_path and os.path.isfile(exe_path):
                if scan_file_with_yara(rules, exe_path):
                    detected_procs.append({
                        'pid': proc.info['pid'],
                        'name': proc.info['name'],
                        'path': exe_path
                    })
                    print(f"[!] Detected process: PID={proc.info['pid']}, Name={proc.info['name']}, Path={exe_path}")
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue
    return detected_procs

def kill_process(pid):
    """Terminates a given process by PID."""
    try:
        p = psutil.Process(pid)
        p.terminate()  # Graceful termination
        time.sleep(1)
        if p.is_running():
            p.kill()  # Force kill
        print(f"[+] Process terminated: PID {pid}")
        return True
    except Exception as e:
        print(f"[!] Failed to terminate process (PID {pid}): {e}")
        return False

# ============================================================
# 4. MAIN
# ============================================================
def main():
    print("="*60)
    print("  Evil_Orange Automatic Detection and Removal Tool")
    print("="*60)
    
    # ADMIN PRIVILEGE CHECK
    try:
        is_admin = os.getuid() == 0  # Linux/Mac
    except AttributeError:
        import ctypes
        is_admin = ctypes.windll.shell32.IsUserAnAdmin() != 0  # Windows
    
    if not is_admin:
        print("[!] WARNING: If you don't run with Administrator privileges, folders like 'WinSxS' may not be scanned!")
        print("[!] Suggestion: Right-click the script -> 'Run as administrator'")
        print("")
    
    # Compile YARA rules
    print("[*] Compiling YARA rules...")
    rules = compile_yara_rule()
    
    # 1. Scan hardcoded paths
    file_hits = scan_specific_paths(rules)
    
    # 2. Scan running processes
    proc_hits = scan_running_processes(rules)
    
    # Merge all findings (file paths)
    all_detected_paths = set(file_hits)
    for p in proc_hits:
        all_detected_paths.add(p['path'])
    
    # ============================================================
    # 5. DISPLAY RESULTS AND CLEAN
    # ============================================================
    print("\n" + "="*60)
    print(f"[*] Total files detected: {len(all_detected_paths)}")
    for idx, path in enumerate(all_detected_paths, 1):
        print(f"    {idx}. {path}")
    
    if not all_detected_paths:
        print("[+] System appears clean. Evil_Orange not detected.")
        return
    
    # Check for --force or -f parameter to skip confirmation
    force_mode = "--force" in sys.argv or "-f" in sys.argv
    
    if not force_mode:
        print("\n[?] Do you want to quarantine (move) these files? (Y/N)")
        choice = input("> ").strip().lower()
        if choice not in ['y', 'yes']:
            print("[i] Operation cancelled. No files were deleted/moved.")
            return
    
    # Kill processes first (files might be locked)
    for proc in proc_hits:
        kill_process(proc['pid'])
    
    # Then quarantine files
    print("\n[*] Quarantining files...")
    success_count = 0
    for path in all_detected_paths:
        if quarantine_file(path):
            success_count += 1
        else:
            # If moving fails, try to delete directly (risky, but optional)
            try:
                os.remove(path)
                print(f"[+] File deleted directly: {path}")
                success_count += 1
            except Exception as e:
                print(f"[!] Delete error: {path} - {e}")
    
    print(f"\n[+] Operation completed. {success_count}/{len(all_detected_paths)} file(s) cleaned.")
    print("[!] NOTE: Quarantine folder is located at 'C:\\Quarantine_EvilOrange'. You can delete it manually if you wish.")

if __name__ == "__main__":
    main()
