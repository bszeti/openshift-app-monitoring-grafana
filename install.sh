# Enable User Workload Monitoring - https://docs.openshift.com/container-platform/4.11/monitoring/enabling-monitoring-for-user-defined-projects.html
oc apply -k kustomize/env/openshift-monitoring

# Create grafana-monitoring namespace and install Grafana and operator
oc apply -k kustomize/env/grafana-monitoring-operator

SATOKEN=`oc sa get-token grafana-thanos -n grafana-monitoring`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/grafana-monitoring/kustomization.yaml
oc apply -k kustomize/env/grafana-monitoring

# Create sso-1 namespace and install Grafana and SSO operator
oc apply -k kustomize/env/sso-1-operator

SATOKEN=`oc sa get-token grafana-thanos -n sso-1`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/sso-1/kustomization.yaml
oc apply -k kustomize/env/sso-1

# Create sso-2 namespace and install Grafana and SSO operator
oc apply -k kustomize/env/sso-2-operator

SATOKEN=`oc sa get-token grafana-thanos -n sso-2`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/sso-2/kustomization.yaml
oc apply -k kustomize/env/sso-2