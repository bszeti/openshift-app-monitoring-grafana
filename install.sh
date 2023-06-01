# Enable User Workload Monitoring - https://docs.openshift.com/container-platform/4.11/monitoring/enabling-monitoring-for-user-defined-projects.html
oc apply -k kustomize/env/openshift-monitoring

### Grafana cluster-scoped ###

# Create grafana-monitoring namespace and install Grafana operator
oc apply -k kustomize/env/grafana-monitoring-operator
while ! oc wait --for condition=established crd/grafanas.integreatly.org; do sleep 1; done

# Create Grafana instance in grafana-monitoring namespace
SATOKEN=`oc extract secret/grafana-thanos-token -n grafana-monitoring --keys=token --to=-`
# Also can get token from auto-created SA Secret:
# SASECRET=$(oc get secret -o jsonpath='{.items[?(@.metadata.annotations.kubernetes\.io/service-account\.name=="grafana-thanos")].metadata.name}' --field-selector type=="kubernetes.io/service-account-token")
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/grafana-monitoring/kustomization.yaml
# Could also patch DataSource afterwards intead of "sed"
# oc patch GrafanaDataSource thanos --type=json -p='[{"op":"replace","path": "/spec/datasources/0/secureJsonData/httpHeaderValue1", "value": "'"Bearer $SATOKEN"'" }]'
oc apply -k kustomize/env/grafana-monitoring

### App namespaces ###

# Create team namespaces - as cluster-admin
oc apply -k kustomize/env/team-a-namespace
oc apply -k kustomize/env/team-b-namespace


# Team-a - [Optional: Switch to user1]

# Create team-a namespace and install Grafana, AMQ and SSO operator
oc apply -k kustomize/env/team-a-operators

# The first time you want to wait for CRDs to become ready on the cluster - Only works as cluster-admin
while ! oc wait --for condition=established crd/activemqartemises.broker.amq.io; do sleep 1; done
while ! oc wait --for condition=established crd/keycloaks.keycloak.org; do sleep 1; done

# Workload + Grafana namespace scoped
SATOKEN=`oc extract secret/grafana-thanos-token -n team-a --keys=token --to=-`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/team-a-workload/kustomization.yaml
oc apply -k kustomize/env/team-a-workload


# Team-b - [Optional: Switch to user2]

# Create team-b namespace and install Grafana, AMQ and SSO operator
oc apply -k kustomize/env/team-b-operators

SATOKEN=`oc extract secret/grafana-thanos-token -n team-b --keys=token --to=-`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/team-b-workload/kustomization.yaml
oc apply -k kustomize/env/team-b-workload

### Alerts ###

# [Optional: Switch back to cluster-admin]

# Enable alert routing for user-defined alerts
oc apply -k kustomize/env/openshift-monitoring-alerts

# Team-a - [Optional: Switch to user1]

# AlertmanagerConfig
oc apply -k kustomize/env/team-a-alerts

# Send message to DLQ to trigger alert
while ! oc wait -n team-a --for condition=Ready --timeout=180s pod/broker-ss-0; do sleep 1; done
oc exec -n team-a broker-ss-0 -- sh -c '/home/jboss/amq-broker/bin/artemis producer --message-count 1 --destination DLQ --url tcp://$(hostname):61617 --user admin --password admin'
while ! oc wait -n team-a --for condition=Ready --timeout=180s pod/broker-ss-1; do sleep 1; done
oc exec -n team-a broker-ss-1 -- sh -c '/home/jboss/amq-broker/bin/artemis producer --message-count 1 --destination DLQ --url tcp://$(hostname):61617 --user admin --password admin'

# Team-b - [Optional: Switch to user2]

# AlertmanagerConfig
oc apply -k kustomize/env/team-b-alerts

# Send message to DLQ to trigger alert
while ! oc wait -n team-b --for condition=Ready --timeout=180s pod/broker-ss-0; do sleep 1; done
oc exec -n team-b broker-ss-0 -- sh -c '/home/jboss/amq-broker/bin/artemis producer --message-count 1 --destination DLQ --url tcp://$(hostname):61617 --user admin --password admin'
