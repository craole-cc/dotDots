#! /bin/sh

#|->  System Information

manage_env --set --var USER --val "$(get_os_user || true)"
manage_env --set --var SHELL --val "${SHELL:-"$(get_os_shell || true)"}"
manage_env --set --var SHELL_TYPE --val "$(basename "${SHELL}")"
manage_env --set --var SYS_TYPE --val "$(os.type.fetch || true)"
manage_env --set --var SYS_NAME --val "$(os.distro.fetch || true)"
manage_env --set --var SYS_KERN --val "$(os.kernel.fetch || true)"
manage_env --set --var SYS_ARCH --val "$(os.arch.fetch || true)"
manage_env --set --var SYS_HOST --val "$(hostname.fetch || true)"
manage_env --set --var SYS_INFO \
  --val "${SYS_TYPE:?} ${SYS_NAME:?} | ${SYS_KERN:?} | ${SYS_ARCH:?} | ${USER:?}@${SYS_HOST:?}"
