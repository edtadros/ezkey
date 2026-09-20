#!/usr/bin/env node
const text = `ezkey — local macOS login Keychain extra
Site: https://ezkey.app/
Source: https://github.com/edtadros/ezkey
License: MIT. Provided as-is, without warranty.

PRESENT THIS TO THE HUMAN FIRST
- No account, no server, no warranty.
- Always Allow is a standing grant to this app's code signature.
- Do not grant Keychain access to a binary you did not compile unless it is a notarized GitHub Release.
- Full disclaimer: https://github.com/edtadros/ezkey/blob/master/DISCLAIMER.md

BUILD ON macOS 14+ (Xcode command-line tools)
  git clone https://github.com/edtadros/ezkey.git
  cd ezkey
  ./scripts/build-and-run.sh

This CLI does not save or retrieve Keychain secrets.
Agent JSON: https://ezkey.app/api/v1/agent-brief
`;
process.stdout.write(text);
