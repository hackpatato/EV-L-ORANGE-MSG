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
    print("[!] YARA kütüphanesi yüklü değil. Kurmak için: pip install yara-python")
    sys.exit(1)

try:
    import psutil
except ImportError:
    print("[!] psutil kütüphanesi yüklü değil. Kurmak için: pip install psutil")
    sys.exit(1)

# ============================================================
# 1. YARA KURALI (direkt içine gömüldü)
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
# 2. KARANTİNA (Quarantine) FONKSİYONU
# ============================================================
def quarantine_file(file_path):
    """Dosyayı karantina klasörüne taşır (silmez, güvenli)."""
    try:
        # Karantina klasörü: C:\Quarantine_EvilOrange
        quarantine_base = os.path.join(os.environ.get('SystemDrive', 'C:'), 'Quarantine_EvilOrange')
        os.makedirs(quarantine_base, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_name = os.path.basename(file_path)
        dest_path = os.path.join(quarantine_base, f"{timestamp}_{file_name}")
        
        shutil.move(file_path, dest_path)
        print(f"[+] Karantinaya alındı: {file_path} -> {dest_path}")
        return True
    except Exception as e:
        print(f"[!] Karantina hatası ({file_path}): {e}")
        return False

# ============================================================
# 3. TARAMA FONKSİYONLARI
# ============================================================
def compile_yara_rule():
    """YARA kuralını derler."""
    try:
        return yara.compile(source=YARA_RULE)
    except yara.SyntaxError as e:
        print(f"[!] YARA kuralında sözdizim hatası: {e}")
        sys.exit(1)

def scan_file_with_yara(rules, file_path):
    """Tek bir dosyayı YARA ile tarar, eşleşirse True döner."""
    if not os.path.isfile(file_path):
        return False
    try:
        matches = rules.match(file_path)
        return len(matches) > 0
    except Exception:
        # Erişim hatası vs. pas geç
        return False

def scan_specific_paths(rules):
    """Kod içinde geçen sabit kalıcılık yollarını tarar."""
    detected_files = []
    
    # 1. C:\Windows\WinSxS\WindowsOrangePeller.exe
    path1 = os.path.join(os.environ.get('SystemRoot', 'C:\\Windows'), 'WinSxS', 'WindowsOrangePeller.exe')
    # 2. %APPDATA%\WindowsSystem64.dll.exe
    path2 = os.path.join(os.environ.get('APPDATA', ''), 'WindowsSystem64.dll.exe')
    # 3. %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\servis.exe
    startup_base = os.path.join(os.environ.get('APPDATA', ''), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
    path3 = os.path.join(startup_base, 'servis.exe')
    
    all_paths = [path1, path2, path3]
    
    print("[*] Bilinen kalıcılık (persistence) yolları taranıyor...")
    for p in all_paths:
        if os.path.exists(p):
            if scan_file_with_yara(rules, p):
                detected_files.append(p)
                print(f"[!] Tespit edildi: {p}")
            else:
                print(f"[+] Temiz (veya erişilemez): {p}")
        else:
            print(f"[-] Dosya mevcut değil: {p}")
    
    return detected_files

def scan_running_processes(rules):
    """Çalışan tüm proseslerin .exe dosyalarını tarar."""
    detected_procs = []
    print("[*] Çalışan prosesler taranıyor (bu biraz sürebilir)...")
    
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
                    print(f"[!] Tespit edilen proses: PID={proc.info['pid']}, Name={proc.info['name']}, Path={exe_path}")
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue
    return detected_procs

def kill_process(pid):
    """Prosesi sonlandır."""
    try:
        p = psutil.Process(pid)
        p.terminate()  # Nazikçe kapat
        time.sleep(1)
        if p.is_running():
            p.kill()  # Zorla kapat
        print(f"[+] Proses sonlandırıldı: PID {pid}")
        return True
    except Exception as e:
        print(f"[!] Proses sonlandırılamadı (PID {pid}): {e}")
        return False

# ============================================================
# 4. ANA (MAIN)
# ============================================================
def main():
    print("="*60)
    print("  Evil_Orange Otomatik Tespit ve Kaldırma Aracı")
    print("="*60)
    
    # YÖNETİCİ (ADMIN) KONTROLÜ
    try:
        is_admin = os.getuid() == 0  # Linux/Mac
    except AttributeError:
        import ctypes
        is_admin = ctypes.windll.shell32.IsUserAnAdmin() != 0  # Windows
    
    if not is_admin:
        print("[!] UYARI: Yönetici (Administrator) yetkisiyle çalıştırmazsanız, 'WinSxS' gibi klasörler taranamayabilir!")
        print("[!] Öneri: Script'e sağ tık -> 'Yönetici olarak çalıştır'")
        print("")
    
    # YARA kurallarını derle
    print("[*] YARA kuralları derleniyor...")
    rules = compile_yara_rule()
    
    # 1. Sabit yolları tara
    file_hits = scan_specific_paths(rules)
    
    # 2. Çalışan prosesleri tara
    proc_hits = scan_running_processes(rules)
    
    # Toplam bulguları birleştir (dosya yolları)
    all_detected_paths = set(file_hits)
    for p in proc_hits:
        all_detected_paths.add(p['path'])
    
    # ============================================================
    # 5. SONUÇLARI GÖSTER VE TEMİZLE
    # ============================================================
    print("\n" + "="*60)
    print(f"[*] Toplam tespit edilen dosya sayısı: {len(all_detected_paths)}")
    for idx, path in enumerate(all_detected_paths, 1):
        print(f"    {idx}. {path}")
    
    if not all_detected_paths:
        print("[+] Sistem temiz görünüyor. Evil_Orange tespit edilmedi.")
        return
    
    # Eğer --force parametresi geldiyse direkt karantinaya al / sil
    force_mode = "--force" in sys.argv or "-f" in sys.argv
    
    if not force_mode:
        print("\n[?] Bu dosyaları karantinaya almak (taşımak) istiyor musunuz? (E/H)")
        choice = input("> ").strip().lower()
        if choice not in ['e', 'evet']:
            print("[i] İşlem iptal edildi. Hiçbir dosya silinmedi/taşınmadı.")
            return
    
    # Önce prosesleri öldür (dosyalar kilitli olabilir)
    for proc in proc_hits:
        kill_process(proc['pid'])
    
    # Sonra dosyaları karantinaya al
    print("\n[*] Dosyalar karantinaya alınıyor...")
    success_count = 0
    for path in all_detected_paths:
        if quarantine_file(path):
            success_count += 1
        else:
            # Eğer taşınamazsa, direkt silmeyi dene (riskli, ama isteğe bağlı)
            try:
                os.remove(path)
                print(f"[+] Dosya doğrudan silindi: {path}")
                success_count += 1
            except Exception as e:
                print(f"[!] Silme hatası: {path} - {e}")
    
    print(f"\n[+] İşlem tamamlandı. {success_count}/{len(all_detected_paths)} dosya temizlendi.")
    print("[!] NOT: Karantina klasörü 'C:\\Quarantine_EvilOrange' içindedir. İsterseniz manuel olarak silebilirsiniz.")

if __name__ == "__main__":
    main()