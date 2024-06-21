#!/usr/bin/env bash


if [[ $1 == "run" ]]; then
    odin run src -out:out/odin-metal-window
  else
    odin build src -out:out/odin-metal-window
fi