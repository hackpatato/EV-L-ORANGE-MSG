rule Evil_Orange_Discord_C2_Agent
{
    meta:
        description = "Evil_Orange Discord C2 Agent (Nim) - https://github.com/hackpatato/EV-L-ORANGE-MSG"
        author = "hackpatato"
        reference = "https://github.com/hackpatato/EV-L-ORANGE-MSG"
        date = "2026-08-18"
        severity = "high"
        confidence = "high"
        
    strings:
        // ========== Nim Runtime ==========
        $nim1 = "nim"
        $nim2 = "NimMain"
        $nim3 = "NimStringV2"
        
        // ========== Evil_Orange'a Özel Stringler ==========
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
        $get_env      = "getEnv(\"DISCORD_TOKEN\"" wide ascii
        $get_env2     = "getEnv(\"DISCORD_CHANNEL\"" wide ascii
        $get_env3     = "getEnv(\"VODKA\"" wide ascii
        
        // ========== Discord API ==========
        $discord_api  = "discord.com/api/v10/channels/" wide ascii
        $discord_auth = "Authorization: Bot " wide ascii
        $messages     = "/messages" wide ascii
        $limit1       = "messages?limit=1" wide ascii
        
        // ========== Kalıcılık (Persistence) ==========
        $persist_nm   = "NativeMessagingHosts" wide ascii
        $persist_ext  = "ExtensionInstallForcelist" wide ascii
        $persist_exe  = "WindowsOrangePeller.exe" wide ascii
        $persist_dll  = "WindowsSystem64.dll.exe" wide ascii
        $persist_svc  = "servis.exe" wide ascii
        $startup_path = "Start Menu\\Programs\\Startup" wide ascii
        
        // ========== Registry ==========
        $reg_edge1    = "HKCU\\Software\\Microsoft\\Edge" wide ascii
        $reg_edge2    = "HKCU\\Software\\Policies\\Microsoft\\Edge" wide ascii
        $reg_add      = "reg.exe add" wide ascii
        
        // ========== Komut Çalıştırma ==========
        $exec_cmd     = "!exec " wide ascii
        $exec_cmd_ex  = "execCmdEx" wide ascii
        
        // ========== Hata Mesajları ==========
        $err_xor      = "xor key error" wide ascii
        $err_xor2     = "XOR İS 64 HEX" wide ascii
        $err_18       = "ERROR NUMBER : 18" wide ascii
        $err_42       = "error 42 . HOW YOU CAN MAKE İT ?" wide ascii
        $err_decrypt  = "a error at xor decrypt !" wide ascii
        
        // ========== XOR+Base64 Pattern ==========
        $xor_pattern  = { 78 6f 72 20 6b 65 79 20 65 72 72 6f 72 }  // "xor key error"
        $base64_enc   = "encode(result)" wide ascii
        $base64_dec   = "decode(b64data)" wide ascii
        
        // ========== Türkçe Karakterler (kod içinde geçiyor) ==========
        $turkish1     = "LANET OLASI" wide ascii
        $turkish2     = "ŞİMDİ" wide ascii
        $turkish3     = "yehuuuu" wide ascii
        
    condition:
        // Nim ile yazıldığını doğrula
        ( $nim1 or $nim2 or $nim3 ) and
        (
            // Ana Evil_Orange imzaları
            ( $evil_title and $vodka ) or
            ( $xor_enc and $xor_dec ) or
            ( $install_pers and $peel2 ) or
            // Discord C2 özellikleri
            ( $discord_api and $discord_auth and $messages ) or
            // Kalıcılık mekanizmaları
            ( $persist_nm or $persist_ext or $persist_exe or $persist_dll or $persist_svc ) or
            // Registry manipülasyonu
            ( $reg_edge1 and $reg_add ) or
            ( $reg_edge2 and $reg_add ) or
            // Komut çalıştırma
            ( $exec_cmd and $exec_cmd_ex ) or
            // Hata mesajları (XOR ile ilgili)
            ( $err_xor and $err_xor2 ) or
            // Türkçe karakterler (projeye özel)
            ( $turkish1 and $turkish2 )
        ) or
        // VEYA doğrudan XOR anahtar kontrolü
        ( $xor_pattern and $base64_enc and $vodka )
}
