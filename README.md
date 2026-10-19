<p align="center">
  <img src="assets/logo.png" alt="Nemotron Autostart logo" width="180">
</p>

# nemotron-autostart

Systemd unit and install/uninstall scripts that run
[llama.cpp](https://github.com/ggerganov/llama.cpp)'s `llama-server` as a
background service hosting the Nemotron-3 Nano 30B (Q8_K_XL) GGUF model.

The service starts at boot, restarts on failure, and is fully independent of
any login shell.

## What it runs

Equivalent to the following shell command, but managed by systemd:

```bash
./llama-server \
    --model ~/models/nemotron3-gguf/Nemotron-3-Nano-30B-A3B-UD-Q8_K_XL.gguf \
    --host 192.168.1.227 \
    --port 30000 \
    --n-gpu-layers 99 \
    --ctx-size 1000000 \
    --threads 10
```

## Assumptions

The unit file hard-codes paths and the listen address. Edit
`nemotron.service` before installing if any of these differ on your host:

| Setting             | Value                                                                  |
| ------------------- | ---------------------------------------------------------------------- |
| User / Group        | `chris` / `chris`                                                      |
| Working directory   | `/home/chris/code/llama.cpp/build/bin`                                 |
| `llama-server` path | `/home/chris/code/llama.cpp/build/bin/llama-server`                    |
| Model path          | `/home/chris/models/nemotron3-gguf/Nemotron-3-Nano-30B-A3B-UD-Q8_K_XL.gguf` |
| Bind address        | `192.168.1.227:30000`                                                  |
| GPU layers          | 99 (all)                                                               |
| Context size        | 1,000,000                                                              |
| CPU threads         | 10                                                                     |

Service tuning:

- `Restart=on-failure`, `RestartSec=5`
- `TimeoutStartSec=600` — large models take a while to map into VRAM
- `LimitNOFILE=1048576`
- Logs to the journal under the identifier `nemotron`

## Install

Clone the repo onto the host that will run the model, then:

```bash
sudo ./install.sh
```

The installer:

1. Verifies the `llama-server` binary and model file exist.
2. Copies `nemotron.service` to `/etc/systemd/system/`.
3. Runs `systemctl daemon-reload`.
4. Enables the unit (starts on boot).
5. Starts the unit and prints its status.

## Uninstall

```bash
sudo ./uninstall.sh
```

Stops the service, disables it, removes the unit file from
`/etc/systemd/system/`, and reloads systemd.

## Operating it

```bash
systemctl status nemotron
sudo systemctl restart nemotron
sudo systemctl stop nemotron
journalctl -u nemotron -f          # follow logs
journalctl -u nemotron --since "1 hour ago"
```

## Heads-up: existing instances

If a `llama-server` is already running from a shell, it will hold port 30000
and the new service will fail to bind. Stop it first:

```bash
pkill -f llama-server
```

Then run `sudo ./install.sh`.

## Files

| File                | Purpose                                  |
| ------------------- | ---------------------------------------- |
| `nemotron.service` | systemd unit                             |
| `install.sh`        | install + enable + start (requires sudo) |
| `uninstall.sh`      | stop + disable + remove (requires sudo)  |
