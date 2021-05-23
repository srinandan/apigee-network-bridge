apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: apigeeservice-port
  namespace: istio-system
spec:
  host: "${apigee_instance_dns}"
  trafficPolicy:
    tls:
      mode: SIMPLE