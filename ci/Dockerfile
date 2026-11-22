# The container CI's jobs run in (.forgejo/workflows/ci.yml), so no job installs anything.
# ci.yml's ci-image job (adham/ci's build-ci-image) builds it only when the registry doesn't have it yet: the tag is ci- and a
# hash of the files in ci/, so changing this file or requirements.txt builds a new image on the next push, with no edit to ci.yml.
# Every base is pinned by digest and Renovate bumps them. Terraform and ShellCheck are copied from their official images;
# Node is the base because the checkout action runs on it.
FROM hashicorp/terraform:1.17.2@sha256:6e9c1e647c31a960dc9b59e13272f9111d90010c10b717f77ffb324767660475 AS terraform
FROM koalaman/shellcheck:v0.11.0@sha256:61862eba1fcf09a484ebcc6feea46f1782532571a34ed51fedf90dd25f925a8d AS shellcheck

FROM node:22.23.5-trixie-slim@sha256:68c76cfad89921b927eae28ba21407475e29d0ce450afcdbe70c1532db042b64

COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=shellcheck /bin/shellcheck /usr/local/bin/shellcheck
COPY requirements.txt /tmp/requirements.txt

# Debian trixie's Python is 3.13. Ansible goes in a venv on PATH, since Debian doesn't allow pip into the system Python.
ENV PATH=/opt/venv/bin:$PATH
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git python3 python3-venv \
 && python3 -m venv /opt/venv \
 && pip install --no-cache-dir -r /tmp/requirements.txt \
 && rm -rf /var/lib/apt/lists/* /tmp/requirements.txt
