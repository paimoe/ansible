# Homelab HTTPS with mkcert

Run these steps on the **Ansible controller** (your PC), before deploying Nginx. `mkcert` is a local certificate authority, not a publicly trusted certificate. Keep the CA private key on the controller, **never** copy it to the homelab or commit it to git.

## First setup

1. Install `mkcert` on your PC. On Ubuntu/Debian, `libnss3-tools` helps mkcert add the CA to Firefox's trust store:

   ```bash
   sudo apt update
   sudo apt install mkcert libnss3-tools
   mkcert -install
   mkcert -CAROOT
   ```

   On a Homebrew system, use `brew install mkcert nss` instead of `apt`. `mkcert -install` creates and trusts the local CA **on this PC only**. Back up the directory printed by `mkcert -CAROOT` securely: it contains the public `rootCA.pem` **and the private `rootCA-key.pem`**.
2. From this repository's `mkcert/` directory, create the website certificate:

   ```bash
   cd /home/paimoe/automation/mkcert
   umask 077
   mkcert -cert-file homelab.pem -key-file homelab-key.pem '*.home.arpa' home.arpa
   ```

   `*.home.arpa` covers `glance`, `immich`, `pihole`, `trilium`, and `karakeep` under `home.arpa`. Do **not** put `rootCA-key.pem` in this directory. The certificates and private key are ignored by git.
3. Deploy from the Ansible directory:

   ```bash
   cd /home/paimoe/automation/ansible
   ansible-playbook -i inventory/hosts.yaml homelab.yaml
   ```

   Ansible copies only `homelab.pem` and `homelab-key.pem` to `/etc/nginx/mkcert/` on the homelab, and checks the Nginx configuration before reloading it. The CA private key stays on your PC.
4. Make sure clients use Pi-hole for DNS: it serves `glance.home.arpa`, `immich.home.arpa`, `pihole.home.arpa`, `trilium.home.arpa`, and `karakeep.home.arpa`. Install **only** the public `rootCA.pem` (from `mkcert -CAROOT`) as a trusted CA on each PC/phone/Apple TV that needs HTTPS. Never distribute `rootCA-key.pem` or `homelab-key.pem` to clients.

   **Firefox:** If you see `SEC_ERROR_UNKNOWN_ISSUER`, don't use *Advanced → Proceed*: that only makes an exception and Firefox will still report an untrusted certificate. In Firefox, open **Settings → Privacy & Security → Certificates → View Certificates → Authorities → Import**, select `rootCA.pem` from the directory printed by `mkcert -CAROOT`, and check **Trust this CA to identify websites** if prompted. Restart Firefox and reload the HTTPS site. If Firefox is on another device, copy **only `rootCA.pem`** to it first—never copy or import `rootCA-key.pem`.

Open `https://glance.home.arpa/` (or any other service name). If a device doesn't use Pi-hole or doesn't trust the CA, its HTTPS connection won't work without further setup. Mobile apps may not trust user-installed CAs. Direct HTTP access to the original published ports remains available; Nginx doesn't disable it.

## Renewal

The mkcert site certificate expires after about **2 years and 3 months**; mkcert does not renew it automatically. Before expiration, on the **same controller using the same CA** (`mkcert -CAROOT`), reissue and redeploy:

```bash
cd /home/paimoe/automation/mkcert
umask 077
mkcert -cert-file homelab.pem -key-file homelab-key.pem '*.home.arpa' home.arpa
openssl x509 -in homelab.pem -noout -dates
cd ../ansible
ansible-playbook -i inventory/hosts.yaml homelab.yaml
```

Ansible replaces the certificate and private key on the server and reloads Nginx. The trusted CA on each device does not need to be reinstalled if you kept the same CA. If the CA is lost or replaced, make a new one, redeploy, and trust its new `rootCA.pem` on every client.
