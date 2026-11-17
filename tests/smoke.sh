#!/usr/bin/env bash
set -euo pipefail

image=${1:?usage: smoke.sh <image>}
work=$(mktemp -d)
name=agent-smoke-$$

cleanup() {
  docker rm -f "$name" > /dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

ssh-keygen -q -t ed25519 -N '' -f "$work/key"
docker run -d --name "$name" -p 127.0.0.1::22 \
  -e "JENKINS_AGENT_SSH_PUBKEY=$(cat "$work/key.pub")" "$image" > /dev/null
port=$(docker port "$name" 22/tcp | head -1 | cut -d: -f2)

agent() {
  ssh -i "$work/key" -p "$port" -o BatchMode=yes -o LogLevel=ERROR \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    jenkins@127.0.0.1 "$@"
}

# Wait for sshd, then connect the way Jenkins does: key-based, non-interactive.
for _ in $(seq 1 30); do agent true 2> /dev/null && break; sleep 1; done
test "$(agent id -un)" = "jenkins"
agent java -version
agent node --version
agent npm --version
agent npx --version
agent git --version
agent git lfs version

sshd_config=$(docker exec "$name" sshd -T)
grep -qx 'permitrootlogin no' <<< "$sshd_config"
grep -qx 'passwordauthentication no' <<< "$sshd_config"
