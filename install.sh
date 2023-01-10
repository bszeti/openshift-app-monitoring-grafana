### Enable User Workload Monitoring - https://docs.openshift.com/container-platform/4.11/monitoring/enabling-monitoring-for-user-defined-projects.html
# Run as cluster-admin
oc apply -k kustomize/env/openshift-monitoring


### Operators ###
oc apply -k kustomize/env/operator-grafana
oc apply -k kustomize/env/operator-amq
oc apply -k kustomize/env/operator-sso
# The first time you want to wait for CRDs to become ready on the cluster
while ! oc wait --for condition=established crd/grafanas.integreatly.org; do sleep 1; done
while ! oc wait --for condition=established crd/activemqartemises.broker.amq.io; do sleep 1; done
while ! oc wait --for condition=established crd/keycloaks.keycloak.org; do sleep 1; done


### Cluster scoped Grafana ###
# Create Grafana instance in grafana-monitoring namespace
SATOKEN=`oc extract secret/grafana-thanos-token -n grafana-monitoring --keys=token --to=-`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/grafana-monitoring/kustomization.yaml
oc apply -k kustomize/env/grafana-monitoring


### Team specific namespaces ### 

# Create team namespaces - as cluster-admin
oc apply -k kustomize/env/team-a-namespace
oc apply -k kustomize/env/team-b-namespace

# Team-a - Optional: Run as user1
# Grafana
SATOKEN=`oc extract secret/grafana-thanos-token -n team-a --keys=token --to=-`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/team-a-workload/kustomization.yaml
# Workloads
oc apply -k kustomize/env/team-a-workload

# Team-b - Optional: Run as user2
# Grafana
SATOKEN=`oc extract secret/grafana-thanos-token -n team-b --keys=token --to=-`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/team-b-workload/kustomization.yaml
# Workloads
oc apply -k kustomize/env/team-b-workload


### Alerts ###

# Run as cluster-admin
# Enable alert routing for user-defined alerts
oc apply -k kustomize/env/openshift-monitoring-alerts

# Optional: Run as user1

# AlertmanagerConfig
oc apply -k kustomize/env/team-a-alerts

# Send message to DLQ to trigger alert
while ! oc wait -n team-a --for condition=Ready --timeout=180s pod/broker-ss-0; do sleep 1; done
oc exec -n team-a broker-ss-0 -- sh -c '/home/jboss/amq-broker/bin/artemis producer --message-count 1 --destination DLQ --url tcp://$(hostname):61617 --user admin --password admin'
while ! oc wait -n team-a --for condition=Ready --timeout=180s pod/broker-ss-1; do sleep 1; done
oc exec -n team-a broker-ss-1 -- sh -c '/home/jboss/amq-broker/bin/artemis producer --message-count 1 --destination DLQ --url tcp://$(hostname):61617 --user admin --password admin'

# Optional: Run as user2

# AlertmanagerConfig
oc apply -k kustomize/env/team-b-alerts

# Send message to DLQ to trigger alert
while ! oc wait -n team-b --for condition=Ready --timeout=180s pod/broker-ss-0; do sleep 1; done
oc exec -n team-b broker-ss-0 -- sh -c '/home/jboss/amq-broker/bin/artemis producer --message-count 1 --destination DLQ --url tcp://$(hostname):61617 --user admin --password admin'
