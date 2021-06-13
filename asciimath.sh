#!/bin/bash

function is_math_renderer_up() {
  pgrep 'AsciiMath Renderer' > /dev/null
}

function start_math_renderer() {
  open -g './AsciiMath Renderer.app'
}

if ! is_math_renderer_up; then
  start_math_renderer
fi

cat << EOF
{"items": [
    {
        "title": "Copy Math",
        "subtitle": "as Image (⌘: as LaTeX)",
        "arg": "asciimath://copyImage",
        "uid": "$1",
        "quicklookurl": "$(pwd)/docs/documentation.html",
        "mods": {
            "cmd": {
                "subtitle": "as LaTeX",
                "arg": "asciimath://copyLatex"
            }
        }
    }
]}
EOF
