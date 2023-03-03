def main(ctx):
    versions = [
        "latest",
    ]

    arches = [
        "amd64",
    ]

    config = {
        "version": None,
        "arch": None,
        "trigger": [],
        "repo": ctx.repo.name,
    }

    stages = []

    for version in versions:
        config["version"] = version

        if config["version"] == "latest":
            config["path"] = "latest"
        else:
            config["path"] = "v%s" % config["version"]

        m = manifest(config)
        inner = []

        for arch in arches:
            config["arch"] = arch

            if config["version"] == "latest":
                config["tag"] = arch
            else:
                config["tag"] = "%s-%s" % (config["version"], arch)

            if config["arch"] == "amd64":
                config["platform"] = "amd64"

            if config["arch"] == "arm64v8":
                config["platform"] = "arm64"

            config["internal"] = "%s-%s" % (ctx.build.commit, config["tag"])

            d = docker(config)
            m["depends_on"].append(d["name"])

            inner.append(d)

        inner.append(m)
        stages.extend(inner)

    after = [
        release(ctx),
        notification(config),
    ]

    for s in stages:
        for a in after:
            a["depends_on"].append(s["name"])

    return stages + after

def docker(config):
    return {
        "kind": "pipeline",
        "type": "docker",
        "name": "%s-%s" % (config["arch"], config["path"]),
        "platform": {
            "os": "linux",
            "arch": config["platform"],
        },
        "steps": steps(config),
        "image_pull_secrets": [
            "registries",
        ],
        "depends_on": [],
        "trigger": {
            "ref": [
                "refs/heads/master",
                "refs/tags/**",
                "refs/pull/**",
            ],
        },
    }

def manifest(config):
    return {
        "kind": "pipeline",
        "type": "docker",
        "name": "manifest-%s" % config["path"],
        "platform": {
            "os": "linux",
            "arch": "amd64",
        },
        "steps": [
            {
                "name": "manifest",
                "image": "plugins/manifest",
                "settings": {
                    "username": {
                        "from_secret": "public_username",
                    },
                    "password": {
                        "from_secret": "public_password",
                    },
                    "spec": "%s/manifest.tmpl" % config["path"],
                    "auto_tag": "true",
                    "ignore_missing": "true",
                },
            },
        ],
        "depends_on": [],
        "trigger": {
            "ref": [
                "refs/heads/master",
                "refs/tags/**",
            ],
        },
    }

def release(ctx):
    return {
        "kind": "pipeline",
        "type": "docker",
        "name": "release",
        "steps": [
            {
                "name": "changelog",
                "image": "thegeeklab/git-chglog",
                "commands": [
                    "git fetch -tq",
                    "git-chglog --no-color --no-emoji %s" % (ctx.build.ref.replace("refs/tags/", "") if ctx.build.event == "tag" else "--next-tag unreleased unreleased"),
                    "git-chglog --no-color --no-emoji -o CHANGELOG.md %s" % (ctx.build.ref.replace("refs/tags/", "") if ctx.build.event == "tag" else "--next-tag unreleased unreleased"),
                ],
            },
            {
                "name": "release",
                "image": "plugins/github-release",
                "settings": {
                    "api_key": {
                        "from_secret": "github_token",
                    },
                    "note": "CHANGELOG.md",
                    "overwrite": True,
                    "title": ctx.build.ref.replace("refs/tags/", ""),
                },
                "when": {
                    "ref": [
                        "refs/tags/**",
                    ],
                },
            },
        ],
        "depends_on": [],
        "trigger": {
            "ref": [
                "refs/heads/master",
                "refs/tags/**",
                "refs/pull/**",
            ],
        },
    }

def notification(config):
    steps = [{
        "name": "notify",
        "image": "plugins/slack",
        "settings": {
            "webhook": {
                "from_secret": "private_rocketchat",
            },
            "channel": "builds",
        },
        "when": {
            "status": [
                "success",
                "failure",
            ],
        },
    }]

    downstream = [{
        "name": "downstream",
        "image": "plugins/downstream",
        "settings": {
            "token": {
                "from_secret": "drone_token",
            },
            "server": "https://drone.owncloud.com",
            "repositories": config["trigger"],
        },
        "when": {
            "status": [
                "success",
            ],
        },
    }]

    if config["trigger"]:
        steps = downstream + steps

    return {
        "kind": "pipeline",
        "type": "docker",
        "name": "notification",
        "platform": {
            "os": "linux",
            "arch": "amd64",
        },
        "clone": {
            "disable": True,
        },
        "steps": steps,
        "depends_on": [
            "release",
        ],
        "trigger": {
            "ref": [
                "refs/heads/master",
                "refs/tags/**",
            ],
            "status": [
                "success",
                "failure",
            ],
        },
    }

def dryrun(config):
    return [{
        "name": "dryrun",
        "image": "plugins/docker",
        "settings": {
            "dry_run": True,
            "auto_tag": True,
            "dockerfile": "%s/Dockerfile.%s" % (config["path"], config["arch"]),
            "repo": "owncloudci/%s" % config["repo"],
            "context": config["path"],
        },
        "when": {
            "ref": [
                "refs/pull/**",
            ],
        },
    }]

def publish(config):
    return [{
        "name": "publish",
        "image": "plugins/docker",
        "settings": {
            "username": {
                "from_secret": "public_username",
            },
            "password": {
                "from_secret": "public_password",
            },
            "auto_tag": True,
            "auto_tag_suffix": config["arch"],
            "dockerfile": "%s/Dockerfile.%s" % (config["path"], config["arch"]),
            "repo": "owncloudci/%s" % config["repo"],
            "context": config["path"],
            "pull_image": False,
        },
        "when": {
            "ref": [
                "refs/heads/master",
                "refs/tags/**",
            ],
        },
    }]

def steps(config):
    return dryrun(config) + publish(config)
