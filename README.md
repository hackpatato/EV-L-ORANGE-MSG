# Evil_Orange 🍊

**Evil_Orange** is a lightweight, educational Proof of Concept (PoC) Command & Control (C2) channel built in **Nim**. It uses the Discord Bot API (REST) as an out-of-band communication channel to issue remote commands and retrieve output from a target endpoint.

> **Disclaimer:** This project is created strictly for educational purposes and authorized security research only. Do not run this software on systems you do not own or do not have explicit permission to test. The author assumes no liability for misuse or damage caused by this program.

---

## Features

- **Discord API C2 Channel:** Leverages HTTPS communication via standard Discord channels to pass commands and exfiltrate output.
- **Environment Variable Support:** Keeps tokens and sensitive IDs out of source control.
- **Cross-Platform:** Written in Nim, compileable for Windows and Linux endpoints.
- **Command Execution:** Supports remote OS command execution using standard `!exec` prefix syntax.
- **Safe Output Formatting:** Automatically truncates long command responses to fit within Discord's 2000-character message limit.

---

## Prerequisites

- **Nim Compiler** (v1.6+ or v2.0+)
- A **Discord Bot Token** and a designated **Channel ID**

---

## Setup & Environment Configuration

To keep sensitive secrets out of public GitHub repositories, set your credentials using environment variables before running the application:

# Windows
nim c -d:ssl -d:release src/evil_orange.nim

# Linux
nim c -d:ssl -d:release --os:linux src/evil_orange.nim 
-----------------------------------------------------------------------------------
#### CMD /WİNDOWS

set DISCORD_TOKEN=YOUR_BOT_TOKEN_HERE
set DISCORD_CHANNEL=YOUR_CHANNEL_ID_HERE 



### Linux / macOS
```bash
export DISCORD_TOKEN="YOUR_BOT_TOKEN_HERE"
export DISCORD_CHANNEL="YOUR_CHANNEL_ID_HERE"





