# pi-helper

🛠️ Small helper scripts for Raspberry Pi.

![AI-Assisted: ChatGPT](https://img.shields.io/badge/AI--Assisted-ChatGPT-blueviolet?logo=openai&logoColor=white)
![AI-Assisted: Copilot](https://img.shields.io/badge/AI--Assisted-GitHub%20Copilot-blue?logo=github&logoColor=white)


---

## 🧪 Installation

* install basic cli tool:
```bash
curl -sL https://raw.githubusercontent.com/willi84/pi-helper/main/install.sh | bash
```
### Plugins
* install a plugin by its name
```bash
pi plugin willi84/kiosk-pi
```

or select from the templates
```bash
pi plugin 
```

---

## 🚀 Usage

* get help: `pi help`
* install packages: `pi install <package1> <package2> ...`
* install plugin from repository: `pi plugin user/project`
* install plugin from templates or manual input: `pi plugin`
* update pi-helper: `pi update`

sample usage:
```bash
pi plugin willi84/kiosk-pi
pi plugin
pi update
pi help
```

## 🔌 Plugins

`pi plugin` assumes that a plugin repository contains an `install.sh`.

Known plugin templates are stored in:

```bash
~/.local/share/pi/config/plugins.json
```

Format:

```json
{
  "plugins": [
    {
      "name": "Kiosk setup",
      "repo": "willi84/kiosk-pi",
      "description": "Kiosk setup"
    }
  ]
}
```

Default templates:

* `willi84/kiosk-pi` - Kiosk setup
* `willi84/test-pi` - Test setup

---

## 🧹 Uninstall

```bash
~/.local/share/pi/uninstall.sh
```

---

## 🧪 Test
after changing the code of libe, run tests to make sure the basics are working:
```bash
bats test/
```
Probably you need to install `bats` first:
```bash
sudo apt install bats
```

## 📝 Changelog
```
./release.sh patch
```
