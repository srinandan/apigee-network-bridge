apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: api-services
  namespace: istio-system
spec:
  hosts:
  - "${apigee_external_name}"
  gateways:
    - api-gateway
  http:
  - match:
    - uri:
        prefix: /
    rewrite:
      authority: "${apigee_instance_dns}"
    route:
    - destination:
        host: "${apigee_instance_dns}"
        port:
          number: 443
      weight: 100
    timeout: 300s
