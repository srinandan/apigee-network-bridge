apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: apigeeservice
  namespace: istio-system
spec:
  hosts:
  - "${apigee_instance_dns}"
  location: MESH_EXTERNAL
  ports:
  - number: 443
    name: https
    protocol: HTTP
  resolution: DNS
