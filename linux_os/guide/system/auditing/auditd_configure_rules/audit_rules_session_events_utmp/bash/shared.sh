# platform = multi_platform_sle

# Include source function library.
. /usr/share/scap-security-guide/remediation_functions

# Perform the remediation
# Perform the remediation for both possible tools: 'auditctl' and 'augenrules'
fix_audit_watch_rule "auditctl" "/var/run/utmp" "wa" "session"
fix_audit_watch_rule "augenrules" "/var/run/utmp" "wa" "session"
