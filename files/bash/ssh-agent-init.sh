# ~/.config/bash/ssh-agent-init.sh
# Managed by Ansible (recommended). Source from ~/.bashrc for interactive shells.
#
# Starts (or reuses) a per-user ssh-agent and loads every private key found
# in ~/.ssh into it, so keys don't need to be added by hand each session.

ssh_agent_env="$HOME/.ssh/agent.env"

ssh_agent_add_all_keys() {
  local key
  for key in "$HOME"/.ssh/*; do
    [ -f "$key" ] || continue
    case "$key" in
      *.pub|*/config|*/known_hosts|*/known_hosts.old|*/authorized_keys|*/agent.env)
        continue ;;
    esac
    grep -q "PRIVATE KEY" "$key" 2>/dev/null && ssh-add "$key" >/dev/null 2>&1
  done
}

# Reuse an agent started by an earlier session, if its socket is still alive
if [ -f "$ssh_agent_env" ]; then
  source "$ssh_agent_env" >/dev/null
fi

ssh-add -l >/dev/null 2>&1
ssh_agent_status=$?

# Exit status 2 means no agent is reachable; start one and record its env
if [ "$ssh_agent_status" -eq 2 ]; then
  ssh-agent -s >"$ssh_agent_env"
  source "$ssh_agent_env" >/dev/null
  ssh_agent_status=1
fi

# Exit status 1 means the agent is running but holds no keys yet
if [ "$ssh_agent_status" -eq 1 ]; then
  ssh_agent_add_all_keys
fi

unset ssh_agent_status
