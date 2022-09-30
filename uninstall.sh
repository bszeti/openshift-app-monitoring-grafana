# Delete teams
oc delete -k kustomize/env/team-a-workload
oc delete -k kustomize/env/team-a-operators
oc delete -k kustomize/env/team-b-workload
oc delete -k kustomize/env/team-b-operators
wait 10
oc delete -k kustomize/env/team-a-namespace
oc delete -k kustomize/env/team-b-namespace

# Delete grafana-monitoring
oc delete -k kustomize/env/grafana-monitoring
oc delete -k kustomize/env/grafana-monitoring-operator

# Remove user-workload-monitoring
oc delete -k kustomize/env/openshift-monitoring
