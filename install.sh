# Enable User Workload Monitoring - https://docs.openshift.com/container-platform/4.11/monitoring/enabling-monitoring-for-user-defined-projects.html
oc apply -k kustomize/env/openshift-monitoring

# Create grafana-monitoring namespace and install Grafana operator
oc apply -k kustomize/env/grafana-monitoring-operator
oc wait --for condition=established crd/grafanas.integreatly.org

# Create Grafana instance in grafana-monitoring namespace
SATOKEN=`oc sa get-token grafana-thanos -n grafana-monitoring`
# Use this in OCP v4.11 instead
# SATOKEN=`oc create token grafana-thanos --duration=9000h -n grafana-monitoring`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/grafana-monitoring/kustomization.yaml
oc apply -k kustomize/env/grafana-monitoring

# Create team namespaces - as cluster-admin
oc apply -k kustomize/env/team-a-namespace
oc apply -k kustomize/env/team-b-namespace

# Optional: Switch to user1

# Create team-a namespace and install Grafana, AMQ and SSO operator
oc apply -k kustomize/env/team-a-operators
oc wait --for condition=established crd/activemqartemises.broker.amq.io
oc wait --for condition=established crd/keycloaks.keycloak.org

SATOKEN=`oc sa get-token grafana-thanos -n team-a`
# Use this in OCP v4.11 instead
# SATOKEN=`oc create token grafana-thanos --duration=9000h -n team-a`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/team-a-workload/kustomization.yaml
oc apply -k kustomize/env/team-a-workload

# Optional: Switch to user2

# Create team-b namespace and install Grafana, AMQ and SSO operator
oc apply -k kustomize/env/team-b-operators

SATOKEN=`oc sa get-token grafana-thanos -n team-b`
# Use this in OCP v4.11 instead
# SATOKEN=`oc create token grafana-thanos --duration=9000h -n team-b`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/team-b-workload/kustomization.yaml
oc apply -k kustomize/env/team-b-workload