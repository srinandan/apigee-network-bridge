apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: api-gateway
  namespace: istio-system
spec:
  selector:
    app: istio-ingressgateway
  servers:
  - hosts:
    - "${apigee_external_name}"
    port:
      name: https-api-443
      number: 443
      protocol: HTTPS
    tls:
      credentialName: api-gateway-certs
      minProtocolVersion: TLSV1_2
      mode: MUTUAL
  - hosts:
    - "${apigee_external_name}"
    port:
      name: http-api-80
      number: 80
      protocol: HTTP