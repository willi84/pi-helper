# pi-helper

🛠️ Small helper scripts for Raspberry Pi.

![AI-Assisted: ChatGPT](https://img.shields.io/badge/AI--Assisted-ChatGPT-blueviolet?logo=openai&logoColor=white)
![AI-Assisted: Copilot](https://img.shields.io/badge/AI--Assisted-GitHub%20Copilot-blue?logo=github&logoColor=white)


---

## 🧪 Installation

```bash
curl -sL https://raw.githubusercontent.com/willi84/pi-helper/main/install.sh | bash
```

Or with a different repository:

```bash
REPO="youruser/yourrepo" bash <(curl -sL https://raw.githubusercontent.com/youruser/yourrepo/main/install.sh)
```

---

## 🚀 Usage

* get help: `pi help`
* install packages: `pi install <package1> <package2> ...`
* update pi-helper: `pi update`

sample usage:
```bash
pi install flask picamera
pi update
```

---

## 🧹 Uninstall

```bash
~/.local/share/pi/uninstall.sh
```

---

## 📝 Changelog
```
./release.sh patch
```