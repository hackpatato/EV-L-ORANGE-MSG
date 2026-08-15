import std/[httpclient, json, os, osproc, strutils]

let token = getnv("DISCORD_TOKEN")

if token == "":
  echo "token error !"
  quit()


echo "YES: ", token[0..9], "..."