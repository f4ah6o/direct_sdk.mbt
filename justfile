# https://github.com/mizchi/moonbit-template
# SPDX-License-Identifier: MIT
# MoonBit Project Commands

target := "js"

default: check test

fmt:
    moon fmt

check:
    moon check --deny-warn --target {{target}}

test:
    moon test --target {{target}}

test-update:
    moon test --update --target {{target}}

run:
    moon run src/main --target {{target}}

info:
    moon info

clean:
    moon clean

release-check: fmt info check test

e2e-create-download-auth talk_id:
    DIRECT_SDK_E2E=1 DIRECT_SDK_E2E_TALK_ID={{talk_id}} moon test src/api/files --target native

e2e-create-download-auth-peer peer_email:
    DIRECT_SDK_E2E=1 DIRECT_SDK_E2E_PEER_EMAIL={{peer_email}} moon test src/api/files --target native
