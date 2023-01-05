# Enable User Workload Monitoring - https://docs.openshift.com/container-platform/4.11/monitoring/enabling-monitoring-for-user-defined-projects.html
oc apply -k kustomize/env/openshift-monitoring

### Grafana

# Create grafana-monitoring namespace and install Grafana operator
oc apply -k kustomize/env/grafana-monitoring-operator
while ! oc wait --for condition=established crd/grafanas.integreatly.org; do sleep 1; done

# Create Grafana instance in grafana-monitoring namespace
# SATOKEN=`oc sa get-token grafana-thanos -n grafana-monitoring`
SATOKEN=`oc extract secret/grafana-thanos-token -n grafana-monitoring --keys=token --to=-`
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

# The first time you want to wait for CRDs to become ready on the cluster
while ! oc wait --for condition=established crd/activemqartemises.broker.amq.io; do sleep 1; done
while ! oc wait --for condition=established crd/keycloaks.keycloak.org; do sleep 1; done


SATOKEN=`oc extract secret/grafana-thanos-token -n team-a --keys=token --to=-`
# SATOKEN=`oc sa get-token grafana-thanos -n team-a`
# Use this in OCP v4.11 instead
# SATOKEN=`oc create token grafana-thanos --duration=9000h -n team-a`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/team-a-workload/kustomization.yaml
oc apply -k kustomize/env/team-a-workload

# Optional: Switch to user2

# Create team-b namespace and install Grafana, AMQ and SSO operator
oc apply -k kustomize/env/team-b-operators

SATOKEN=`oc extract secret/grafana-thanos-token -n team-b --keys=token --to=-`
# SATOKEN=`oc sa get-token grafana-thanos -n team-b`
# Use this in OCP v4.11 instead
# SATOKEN=`oc create token grafana-thanos --duration=9000h -n team-b`
sed -i '' "s/Bearer .*/Bearer $SATOKEN/" kustomize/env/team-b-workload/kustomization.yaml
oc apply -k kustomize/env/team-b-workload


### Alerts

# Optional: Switch back to cluster-admin

# Enable alert routing for user-defined alerts
oc apply -k kustomize/env/openshift-monitoring-alerts

# Optional: Switch to user1

oc apply -k kustomize/env/team-a-alerts
oc exec -n team-a broker-ss-0 -- sh -c '/home/jboss/amq-broker/bin/artemis producer --message-count 1 --destination DLQ --url tcp://$(hostname):61617 --user admin --password admin'

# Optional: Switch to user2

oc apply -k kustomize/env/team-b-alerts
oc exec -n team-b broker-ss-0 -- sh -c '/home/jboss/amq-broker/bin/artemis producer --message-count 1 --destination DLQ --url tcp://$(hostname):61617 --user admin --password admin'
