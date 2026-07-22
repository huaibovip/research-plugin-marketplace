import json
import shutil
import subprocess
from pathlib import Path

# 仓库地址
REPO_URL = "https://github.com/huaibovip/research-marketplace.git"
REF = "main"

CLAUDE_TYPE = "git-subdir"
CODEX_TYPE = "git-subdir"
COPILOT_TYPE = "github"

CLAUDE_AGENT_DIR = Path(".claude-plugin")
CODEX_AGENT_DIR = Path(".codex-plugin")
COPILOT_AGENT_DIR = Path(".github/plugin")

MARKETPLACE_FILE = "marketplace.json"
TMP_REPO_DIR = Path(".tmp/research-marketplace")


def clone_repo(url, branch, dest, depth=1, force=False):
    """
    阻塞下载 Git 仓库
    """
    dest = Path(dest)

    if force and dest.exists():
        shutil.rmtree(dest)

    if dest.exists():
        print(f"目录 {dest} 已存在，跳过下载")
        return

    cmd = [
        "git",
        "clone",
        "--branch",
        branch,
        "--single-branch",
        "--depth",
        str(depth),
        url,
        str(dest),
    ]

    subprocess.run(cmd, check=True)
    print("下载完成")


def merge_plugin_metadata(
    plugin: dict,
    metadata_dir,
    fields: dict | tuple,
) -> None:
    """
    从对应插件目录的 metadata_dir/plugin.json 合并元数据到 marketplace.json

    Args:
        plugin: marketplace 中的插件对象
        fields: 需要同步的字段
    """
    metadata_dir = Path(metadata_dir)
    metadata_file = metadata_dir / "plugin.json"
    if not metadata_file.is_file():
        return

    with metadata_file.open("r", encoding="utf-8") as f:
        metadata = json.load(f)

    if isinstance(fields, dict):
        for field, default_value in fields.items():
            value = metadata.get(field, default_value)
            if value is not None:
                plugin[field] = value
    else:
        for field in fields:
            if field in metadata:
                plugin[field] = metadata[field]


def convert_marketplace(
    input_file,
    output_file,
    agent_type,
    agent_dir,
    fields,
    url_key="url",
):
    input_file = input_file.resolve()
    output_file = output_file.resolve()

    with open(input_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    for plugin in data.get("plugins", []):
        source = plugin["source"]
        if isinstance(source, str):
            url = REPO_URL
            plugin_dir = source
            ref = REF
        elif isinstance(source, dict):
            url = source.get(url_key, REPO_URL)
            plugin_dir = source["path"]
            ref = source.get("ref", REF)
        else:
            raise ValueError(f"Invalid source type: {type(source)}")

        metadata_dir = TMP_REPO_DIR / plugin_dir / agent_dir
        merge_plugin_metadata(plugin, metadata_dir, fields)

        plugin["source"] = {
            "source": agent_type,
            url_key: url,
            "path": plugin_dir,
            "ref": ref,
        }

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print(f"Converted {input_file} -> {output_file}")


def convert_readme(input_file, output_file, ref):
    input_file = input_file.resolve()
    output_file = output_file.resolve()

    if not input_file.is_file():
        print(f"README 文件 {input_file} 不存在，跳过")
        return

    text = input_file.read_text(encoding="utf-8")
    text = text.replace(
        "add huaibovip/research-marketplace",
        f"add huaibovip/research-marketplace@{ref}",
    )
    text = text.replace(
        "add git@github.com:huaibovip/research-marketplace.git",
        f"add git@github.com:huaibovip/research-marketplace.git#{ref}",
    )
    output_file.write_text(text, encoding="utf-8")
    print(f"Copied README: {input_file} -> {output_file}")


if __name__ == "__main__":
    clone_repo(
        url=REPO_URL,
        branch=REF,
        dest=TMP_REPO_DIR,
        depth=1,
        force=True,
    )

    fields = {"homepage": None, "category": "research"}
    claude_file = TMP_REPO_DIR / CLAUDE_AGENT_DIR / MARKETPLACE_FILE
    claude_new_file = CLAUDE_AGENT_DIR / MARKETPLACE_FILE
    claude_new_file.parent.mkdir(parents=True, exist_ok=True)
    convert_marketplace(
        claude_file,
        claude_new_file,
        CLAUDE_TYPE,
        CLAUDE_AGENT_DIR,
        fields,
    )

    fields = {"homepage": None, "category": "Research"}
    codex_dir = Path(".agents/plugins")
    codex_file = TMP_REPO_DIR / codex_dir / MARKETPLACE_FILE
    codex_new_file = codex_dir / MARKETPLACE_FILE
    codex_new_file.parent.mkdir(parents=True, exist_ok=True)
    convert_marketplace(
        codex_file,
        codex_new_file,
        CODEX_TYPE,
        CODEX_AGENT_DIR,
        fields,
    )

    fields = ("homepage", "repository", "version", "license")
    copilot_file = TMP_REPO_DIR / COPILOT_AGENT_DIR / MARKETPLACE_FILE
    copilot_new_file = COPILOT_AGENT_DIR / MARKETPLACE_FILE
    copilot_new_file.parent.mkdir(parents=True, exist_ok=True)
    convert_marketplace(
        copilot_file,
        copilot_new_file,
        COPILOT_TYPE,
        COPILOT_AGENT_DIR,
        fields,
        url_key="repo",
    )

    readme_file = TMP_REPO_DIR / "README.md"
    convert_readme(readme_file, Path("README.md"), 'git')
