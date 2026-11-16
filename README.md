# docker-jenkins-agent-node

Jenkins build agent with Java and Node.js LTS. Jenkins connects to it over SSH.

It extends the official [`jenkins/ssh-agent`](https://github.com/jenkinsci/docker-ssh-agent) image with Node.js from the official [`node`](https://github.com/nodejs/docker-node) image. Images are built for `linux/amd64` and `linux/arm64` and ship with an SBOM, build provenance and a keyless signature.

## Images

Images are published to GitHub Container Registry as `ghcr.io/think-cube/jenkins-agent-node`.

| Tag | Meaning | Changes? |
|---|---|---|
| `1.0.0` | Exact release | Never |
| `1.0`, `1`, `latest` | Newest matching release | With each release |
| `edge` | Newest build of `main` | With each merge and weekly rebuild |
| `edge-YYYYMMDD` | Weekly rebuild of `main` with current OS patches | Never |
| `sha-<commit>` | Build of one `main` commit | Never |

For production, pin by digest: `ghcr.io/think-cube/jenkins-agent-node:1.0.0@sha256:...`.

## What is in the image

- Java runtime, SSH server, `git` and `git-lfs` from `jenkins/ssh-agent`
- Node.js LTS with `npm`, `npx` and `corepack`

The exact versions are on the `FROM` lines of the `Dockerfile`. A new major Node.js line is adopted deliberately, in a new major version of this image.

## Usage

Start the agent with the public half of the key Jenkins will use:

```bash
docker run -d --name jenkins-agent \
  -p 2222:22 \
  -e "JENKINS_AGENT_SSH_PUBKEY=ssh-ed25519 AAAA..." \
  ghcr.io/think-cube/jenkins-agent-node:1
```

The key can also be passed as the first argument instead of the environment variable.

In Jenkins, add a node that launches via SSH:

- **Host**: the Docker host, **Port**: `2222`
- **Credentials**: SSH username `jenkins` with the matching private key
- **Remote root directory**: `/home/jenkins/agent`
- **Host key verification**: verify against the agent's host key, which is generated on first start and kept in the container

Root login and password authentication are disabled. `sshd` runs as root inside the container because it has to switch to the `jenkins` user for each session; builds run as `jenkins` (UID/GID `1000`).

## Environment variables

| Variable | Description |
|---|---|
| `JENKINS_AGENT_SSH_PUBKEY` | Public key allowed to log in as `jenkins` |

Other variables passed with `-e` are visible to build sessions as well.

## Verify an image

Check the signature:

```bash
cosign verify ghcr.io/think-cube/jenkins-agent-node:1.0.0 \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github\.com/Think-Cube/workflows/\.github/workflows/container-image\.yml@refs/tags/v.+$'
```

Read the SBOM and provenance:

```bash
docker buildx imagetools inspect ghcr.io/think-cube/jenkins-agent-node:1.0.0 --format '{{ json .SBOM }}'
docker buildx imagetools inspect ghcr.io/think-cube/jenkins-agent-node:1.0.0 --format '{{ json .Provenance }}'
```

## Build and test locally

```bash
docker build -t jenkins-agent-node:local .
bash tests/smoke.sh jenkins-agent-node:local
```

The smoke test starts the agent, logs in over SSH with a throwaway key the way Jenkins does, and checks the tools and the SSH hardening.

## Support

Only the newest release receives fixes. `main` is rebuilt every week, and images with fixable critical vulnerabilities are not published. Report security issues through [GitHub private vulnerability reporting](https://github.com/Think-Cube/docker-jenkins-agent-node/security/advisories/new).

## License

This project is licensed under the [MIT License](LICENSE).

## Contribution

Feel free to contribute by opening issues or pull requests. Your feedback and improvements are highly appreciated!
