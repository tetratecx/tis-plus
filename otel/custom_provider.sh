# namespace specific tracing to specific endpoint configured by extension provider in mesh config.
kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: otel-demo
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 11
EOF

# namespace specific tracing to specific endpoint configured by extension provider in mesh config.
kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: otel-demo
  namespace: httpbin
spec:
  tracing:
  - providers:
    - name: tetrate-oap
    randomSamplingPercentage: 21
EOF
