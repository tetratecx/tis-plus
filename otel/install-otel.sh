# install operator
# This script installs otel LB exporter and otel collector
# it supports tail based sampling

kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: observability
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: loadbalancer-role
  namespace: observability
rules:
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - list
  - watch
  - get
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loadbalancer
  namespace: observability
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: loadbalancer-rolebinding
  namespace: observability
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: loadbalancer-role
subjects:
- kind: ServiceAccount
  name: loadbalancer
  namespace: observability
---
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-lb-exporter
  namespace: observability
spec:
  image: docker.io/otel/opentelemetry-collector-contrib:latest
  serviceAccount: loadbalancer
  managementState: managed
  config: |
    receivers:
      otlp:
        protocols:
          grpc: {}
    processors: {}
    exporters:
      logging:
        loglevel: debug
      loadbalancing:
        routing_key: "traceID"
        protocol:
          otlp:
            tls:
              insecure: true
        resolver:
          k8s:
            service: otel-col-backends-collector-headless.observability
            ports:
            - 4317
    service:
      pipelines:
        traces:
          receivers:
            - otlp
          processors: []
          exporters:
            - loadbalancing
            - logging
---
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-col-backends
  namespace: observability
spec:
  managementState: managed
  image: docker.io/otel/opentelemetry-collector-contrib:latest
  replicas: 5
  config: |
    receivers:
      otlp:
        protocols:
          grpc: {}
          http: {}
    processors:
      tail_sampling:
        decision_wait: 10s
        num_traces: 100
        expected_new_traces_per_sec: 10
        decision_cache:
            sampled_cache_size: 1000
        policies: [ 
          {
                # Rule -  For all non 200 status code, sampling rate 100 percent 
                name: all-failure-status-policy,
                type: and,
                and:
                {
                    and_sub_policy:
                    [
                        {
                            # filter by http.status_code
                            name: http-status-code-policy,
                            type: string_attribute,
                            string_attribute:
                                {
                                    key: http.status_code,
                                    values: ["20[01]"],
                                    enabled_regex_matching: true,
                                    invert_match: true,
                                },
                        },
                        {
                            # apply probabilistic sampling
                            name: probabilistic-policy,
                            type: probabilistic,
                            probabilistic: { sampling_percentage: 100 },
                        },
                        
                    ],
                },
            },
            {
                # Rule - percentage sample if all success
                name: all-success-status-policy,
                type: and,
                and:
                {
                    and_sub_policy:
                    [
                        {
                            # filter by http.status_code
                            name: http-status-code-policy,
                            type: string_attribute,
                            string_attribute:
                                {
                                    key: http.status_code,
                                    values: ["20[01]"],
                                    enabled_regex_matching: true,
                                },
                        },
                        {
                            # apply probabilistic sampling
                            name: probabilistic-policy,
                            type: probabilistic,
                            probabilistic: { sampling_percentage: 1 },
                        },
                        
                    ],
                },
            }, 
        ]
    extensions:
      basicauth:
        client_auth:
          username: elastic
          password: changeme
    exporters:
      elasticsearch: # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/elasticsearchexporter
        endpoint: https://elastic.example.com:9200
        auth:
          authenticator: basicauth
      zipkin/oap:
        endpoint: http://zipkin.tis-plus-system.svc:9411/api/v2/spans
        tls:
          insecure: true
      zipkin/ext:
        endpoint: http://zipkin.istio-system.svc:9411/api/v2/spans
        tls:
          insecure: true
      logging:
        loglevel: debug
    service:
      extensions: [basicauth]
      pipelines:
        traces:
          processors:
          - tail_sampling
          receivers:
          - otlp
          exporters:
          - zipkin/oap
          - zipkin/ext
          - logging
EOF

# debug
#k -n observability logs -f -l app.kubernetes.io/name=otel-col-backends-collector  --max-log-requests 5
#k -n observability logs -f -l app.kubernetes.io/instance=observability.otel-lb-exporter
# n=1;while true;do curl http://httpbin:80/status/500 -I ;echo $n; n=$((n+1));sleep 1;done