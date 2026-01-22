# syntax=docker/dockerfile:1.7
FROM mcr.microsoft.com/powershell:debian-12

# ----------------------------
# Runtime paths (mounted + immutable)
# ----------------------------
ENV CONFIG_DIR=/config \
    OVERLAY_DIR=/config/Overlay \
    SERVER_DIR=/config/Server \
    SERVER_ROOT=/server \
    WORK_DIR=/tmp/.overlay-work \
    SCRIPT_MODULES=/config/Scripts/Modules \
    SCRIPT_HOOKS=/config/Scripts/Hooks \
    LANCOMMANDER_HOME=/home/lancommander \
    BASE_MODULES=/usr/local/share/powershell/Modules
# ----------------------------
# User + directories
# ----------------------------
RUN useradd -m -u 1337 -d "${LANCOMMANDER_HOME}" -s /usr/sbin/nologin lancommander \
    && mkdir -p \
        "${LANCOMMANDER_HOME}" \
        "${CONFIG_DIR}" \
        "${OVERLAY_DIR}" \
        "${SERVER_DIR}" \
        "${WORK_DIR}" \
        "${SERVER_ROOT}" \
        "${SCRIPT_MODULES}" \
        "${SCRIPT_HOOKS}" \
        "${BASE_MODULES}" \
    && chown -R lancommander:lancommander \
        "${LANCOMMANDER_HOME}" \
        "${CONFIG_DIR}" \
        "${OVERLAY_DIR}" \
        "${SERVER_DIR}" \
        "${SCRIPT_MODULES}" \
        "${SCRIPT_HOOKS}"

# ----------------------------
# Built-in (immutable) PowerShell modules shipped with this image
#   - BASE_MODULES: modules PowerShell should load from the image
#
# NOTE:
# Do NOT bake modules into /config at build time. /config is typically a volume and
# will hide anything placed there in the image.
# ----------------------------
COPY Modules/ "${BASE_MODULES}/"

# ----------------------------
# Entrypoint
# ----------------------------
COPY ./Entrypoint.ps1 /usr/local/bin/entrypoint.ps1
RUN chmod +x /usr/local/bin/entrypoint.ps1

# ----------------------------
# Runtime
# ----------------------------
WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]