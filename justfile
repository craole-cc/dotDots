set windows-shell := ["C:\\Program Files\\Git\\bin\\sh.exe", "-c"]
set unstable := true
set fallback := true

# ~@ Format all justfiles with just and other files with treefmt
fmt:
    if command -v fmtree >/dev/null 2>&1; then \
        fmtree; \
    else \
        find . -name "justfile" -o -name "*.justfile" -o -name ".justfile" | \
          while read -r file; do echo "Formatting $file"; \
            just --fmt --unstable --justfile "$file" || \
            printf "[ERROR] Failed to format: %s\n" "$file"; \
          done; \
        command -v treefmt  >/dev/null 2>&1 && \
          treefmt --allow-missing-formatter --clear-cache --fail-on-change; \
    fi

# ~@ Quick commit with message
push MESSAGE:
    jj describe --message "{{ MESSAGE }}"
    jj bookmark set main --revision=@
    jj git push

# ~@ Interactive describe commit
push-interactive:
    jj describe
    jj bookmark set main --revision=@
    jj git push

wq-wallter:
    cargo-watch --quiet --clear --exec 'run --package wallter --quiet'
