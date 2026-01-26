# syntax=docker/dockerfile:1.7
FROM mcr.microsoft.com/powershell:debian-12

# ----------------------------
# Runtime paths (mounted + immutable)
# ----------------------------
ENV CONFIG_DIR=/config \
    OVERLAY_DIR=/config/Overlay \
    SERVER_DIR=/config/Server \
    SERVER_ROOT=/config/Merged \
    WORK_DIR=/config/.overlay-work \
    LANCOMMANDER_HOME=/home/lancommander \
    BASE_MODULES=/usr/local/share/powershell/Modules \
    BASE_HOOKS=/usr/local/share/powershell/Hooks \
    USER_MODULES=/config/Scripts/Modules \
    USER_HOOKS=/config/Scripts/Hooks \
    START_EXE="" \
    START_ARGS="" \
    HTTP_FILESERVER_ENABLED="" \
    HTTP_FILESERVER_ROOT=/config/Server

# ----------------------------
# User + directories
# ----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1337 -d "${LANCOMMANDER_HOME}" -s /usr/sbin/nologin lancommander \
    && mkdir -p \
        "${LANCOMMANDER_HOME}" \
        "${CONFIG_DIR}" \
        "${OVERLAY_DIR}" \
        "${SERVER_DIR}" \
        "${WORK_DIR}" \
        "${SERVER_ROOT}" \
        "${BASE_MODULES}" \
        "${BASE_HOOKS}" \
    && chown -R lancommander:lancommander \
        "${LANCOMMANDER_HOME}" \
        "${CONFIG_DIR}" \
        "${OVERLAY_DIR}" \
        "${SERVER_DIR}"

# ----------------------------
# Built-in (immutable) PowerShell modules shipped with this image
#   - BASE_MODULES: modules PowerShell should load from the image
#
# NOTE:
# Do NOT bake modules into /config at build time. /config is typically a volume and
# will hide anything placed there in the image.
# ----------------------------
COPY Modules/ "${BASE_MODULES}/"
# COPY Hooks/ "${BASE_HOOKS}/" # (No built-in hooks for now)

# ----------------------------
# Entrypoint
# ----------------------------
COPY ./Entrypoint.ps1 /usr/local/bin/entrypoint.ps1
RUN chmod +x /usr/local/bin/entrypoint.ps1

# ----------------------------
# Nginx configuration template
# ----------------------------
RUN mkdir -p /usr/local/share
COPY ./nginx.conf /usr/local/share/nginx.conf.template

# ----------------------------
# Runtime
# ----------------------------
WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]